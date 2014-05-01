class Message
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :group_id, :one_to_one_id, :user_id, :rank, :text, :attachment_file,
    :mentioned_user_ids, :message_attachment_id, :attachment_url, :attachment_content_type,
    :attachment_preview_url, :attachment_preview_width, :attachment_preview_height,
    :attachment_metadata, :client_metadata, :received, :created_at, :expires_in, :expires_at
  hash_key :attrs
  sorted_set :likes

  validates :user_id, presence: true
  validate :group_id_or_one_to_one_id?, :not_blocked?, :text_under_limit?, :text_or_attachment_set?

  TEXT_LIMIT = 1_000


  def initialize(attributes = {})
    super

    if id.present?
      to_int(:rank, :attachment_preview_width, :attachment_preview_height, :created_at, :expires_in, :expires_at)
      to_bool(:received)
    end
  end

  def save
    return unless valid?

    generate_id
    sanitize_mentioned_user_ids
    save_message_attachment

    redis.multi do
      write_attrs
      add_to_conversation
    end

    increment_user_stats
    increment_stats

    true
  end

  def rank
   @rank ||= attrs[:rank].to_i
  end

  def user
    @user ||= User.find_by(id: user_id) if user_id
  end

  def group
    @group ||= Group.find_by(id: group_id) if group_id
  end

  def one_to_one
    @one_to_one ||= OneToOne.new(id: one_to_one_id) if one_to_one_id
  end

  def message_attachment
    @message_attachment ||= MessageAttachment.find_by(id: message_attachment_id) if message_attachment_id
  end

  def mentioned_user_ids
    @mentioned_user_ids.present? ? @mentioned_user_ids.to_s.split(',') : []
  end

  def mentioned_all?
    mentioned_user_ids.include?('-1')
  end

  def mentioned_users
    if mentioned_user_ids.present?
      user_ids = mentioned_all? ? conversation.fetched_member_ids : mentioned_user_ids
      user_ids.delete(user_id)
      User.where(id: user_ids)
    else
      []
    end
  end

  def mentioned?(user)
    user.id != user_id && (mentioned_all? || mentioned_user_ids.include?(user.id))
  end

  def like(user)
    likes[user.id] = Time.current.to_f unless likes.member?(user.id)
  end

  def unlike(user)
    likes.delete(user.id)
  end

  def paginated_liked_user_ids(options = {})
    max = 50
    options[:limit] ||= 10
    options[:limit] = 1 if options[:limit].to_i <= 0
    options[:limit] = max if options[:limit].to_i > max
    options[:limit] = options[:limit].to_i
    options[:offset] = options[:offset].to_i

    start = options[:offset]
    stop = options[:offset] + options[:limit] - 1

    likes.revrange(start, stop)
  end

  def paginated_liked_users(options = {})
    user_ids = paginated_liked_user_ids(options)

    if user_ids.present?
      field_order = user_ids.map{ |id| "'#{id}'" }.join(',')
      User.includes(:avatar_image, :avatar_video).where(id: user_ids).order("FIELD(id, #{field_order})")
    else
      []
    end
  end

  def conversation
    group || one_to_one
  end


  private

  def generate_id
    return if id.present?

    # Exclude L to avoid any confusion
    chars = [*'a'..'k', *'m'..'z', *0..9]

    loop do
      self.id = Array.new(10){ chars.sample }.join
      break unless attrs.exists?
    end
  end

  def sanitize_mentioned_user_ids
    @mentioned_user_ids = @mentioned_user_ids.to_s.split(',') unless @mentioned_user_ids.is_a?(Array)

    if @mentioned_user_ids.blank? || conversation.nil?
      @mentioned_user_ids = nil
    else
      member_ids = ['-1'] # @all mention
      member_ids += conversation.fetched_member_ids

      sanitized_user_ids = @mentioned_user_ids & member_ids
      @mentioned_user_ids = sanitized_user_ids.join(',')
    end
  end

  def group_id_or_one_to_one_id?
    attrs = [group_id, one_to_one_id]
    errors.add(:base, "Must specify exactly one of group_id or one_to_one_id.") if attrs.all?(&:blank?) || attrs.all?(&:present?)
  end

  def not_blocked?
    errors.add(:base, "Sorry, you can't send a 1-1 message to that user.") if one_to_one.try(:blocked?)
  end

  def text_under_limit?
    errors.add(:base, "Text is too long (maximum is #{TEXT_LIMIT} characters)") if text.present? && text.size > TEXT_LIMIT
  end

  def text_or_attachment_set?
    errors.add(:base, "Either text or an attachment is required.") unless text.present? || attachment_file.present? || attachment_url.present?
  end

  def save_message_attachment
    if attachment_file.present?
      @message_attachment = MessageAttachment.new(message_id: id, message: self, attachment: attachment_file)
      @message_attachment.save!
    elsif attachment_url.present?
      @message_attachment = MessageAttachment.new(message_id: id, message: self, remote_attachment_url: attachment_url)
      @message_attachment.save!
    end
  end

  def write_attrs
    self.created_at = Time.current.to_i
    to_bool(:received)

    if expires_in.present?
      self.expires_in = expires_in.to_i
      self.expires_at = (Time.current + expires_in).to_i
    end

    if @message_attachment && @message_attachment.attachment.present?
      self.attachment_url = @message_attachment.attachment.url
      self.attachment_content_type = @message_attachment.content_type
      self.attachment_preview_url = @message_attachment.preview_url
      self.attachment_preview_width = @message_attachment.preview_width
      self.attachment_preview_height = @message_attachment.preview_height
      self.message_attachment_id = @message_attachment.id
    end

    # If this message was received, change the sender
    if received
      self.user_id = one_to_one.other_user_id(user)
      @user = nil # Clear memoizer
    end

    redis.multi do
      self.attrs.bulk_set(id: id, group_id: group_id, one_to_one_id: one_to_one_id, user_id: user_id,
                          text: text, mentioned_user_ids: @mentioned_user_ids, message_attachment_id: message_attachment_id,
                          attachment_url: attachment_url, attachment_content_type: attachment_content_type,
                          attachment_preview_url: attachment_preview_url, attachment_preview_width: attachment_preview_width,
                          attachment_preview_height: attachment_preview_height, attachment_metadata: attachment_metadata,
                          client_metadata: client_metadata, received: received,
                          created_at: created_at, expires_in: expires_in, expires_at: expires_at)

      if expires_in.present?
        redis.expire(attrs.key, expires_in)
        conversation.message_id_expirations[id] = expires_at
      end
    end
  end

  # Atomically set the rank and add it to the conversation's message list
  def add_to_conversation
    convo = conversation

    if convo
      lua_script = %{local rank = redis.call('INCR', KEYS[1]); redis.call('HSET', KEYS[2], 'rank', rank); redis.call('ZADD', KEYS[3], rank, ARGV[1])}
      redis.eval lua_script, {keys: [convo.rank.key, attrs.key, convo.message_ids.key], argv: [id]}
    end
  end

  def increment_user_stats
    key = user.metrics.key
    recipients = conversation.members(includes: nil).reject{ |m| m.id == user.id }

    user.redis.pipelined do
      if group
        user.redis.hincrby(key, :sent_group_messages_count, 1)

        recipients.each do |recipient|
          user.redis.hincrby(recipient.metrics.key, :received_group_messages_count, 1)
          user.redis.hincrby(recipient.metrics.key, :received_messages_count, 1)
        end
      elsif one_to_one
        user.redis.hincrby(key, :sent_one_to_one_messages_count, 1)

        recipient_key = one_to_one.other_user(user).metrics.key
        user.redis.hincrby(recipient_key, :received_one_to_one_messages_count, 1)
        user.redis.hincrby(recipient_key, :received_messages_count, 1)
      end

      user.redis.hincrby(key, :sent_messages_count, 1)
    end
  end

  def increment_stats
    if group
      StatsD.increment('messages.group.nonregistered.sent')

      # For each message sent, count all the members in the group,
      # (except the sender) as recipients
      recipients = conversation.fetched_member_ids.size - 1
      StatsD.increment('messages.group.nonregistered.received', recipients) if recipients > 0
    elsif one_to_one
      recipient = one_to_one.other_user(user)

      registered_qualifier = recipient.account.registered? ? 'registered' : 'nonregistered'
      StatsD.increment("messages.one_to_one.#{registered_qualifier}.sent")
      StatsD.increment("messages.one_to_one.#{registered_qualifier}.received")

      # Was this a message that was fetched/imported from another service?
      sender_qualifier = (received && !user.account.registered?) ? 'external' : 'internal'
      StatsD.increment("messages.one_to_one.by_source.#{sender_qualifier}.sent")
      StatsD.increment("messages.one_to_one.by_source.#{sender_qualifier}.received")
    end
  end
end
