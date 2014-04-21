class Message
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :group_id, :one_to_one_id, :user_id, :rank, :text, :attachment_file,
    :mentioned_user_ids, :message_attachment_id, :attachment_url, :attachment_content_type,
    :attachment_preview_url, :attachment_preview_width, :attachment_preview_height,
    :attachment_metadata, :client_metadata, :original_message_id, :forward_message_id, :actor_id,
    :attachment_message_id, :created_at, :expires_in, :expires_at

  hash_key :attrs
  list :ancestor_message_ids
  list :forwards # JSON strings for each forward on this or any forwarded/decendant messages (all levels deep)
  sorted_set :liker_ids # User IDs who have liked this specific message
  list :likes # JSON strings for each like on this or any forwarded/decendant messages (all levels deep)
  list :exports # JSON strings for each export on this or any forwarded/decendant messages (all levels deep)

  validates :user_id, presence: true
  validate :group_id_or_one_to_one_id?, :not_blocked?, :text_under_limit?, :text_or_attachment_set?

  TEXT_LIMIT = 1_000


  def initialize(attributes = {})
    super
    to_int(:rank, :attachment_preview_width, :attachment_preview_height, :created_at, :expires_in, :expires_at) if id.present?
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

    set_ancestor_list
    increment_forward_stats
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
    return if meta_message? || liker_ids.member?(user.id)

    now = Time.current.to_f
    liker_ids[user.id] = now
    like_json = {message_id: id, user_id: user.id, timestamp: now}.to_json

    if forward_message
      ancestor_ids = ancestor_message_ids.values

      redis.pipelined do
        [*ancestor_ids, id].each do |message_id|
          redis.rpush("message:#{message_id}:likes", like_json)
        end
      end
    else
      likes << like_json
    end
  end

  # Obsolete?
  def unlike(user)
    # likes.delete(user.id)
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

    liker_ids.revrange(start, stop)
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

  def original_message
    @original_message ||= Message.new(id: original_message_id) if original_message_id
  end

  def forward_message
    @forward_message ||= Message.new(id: forward_message_id) if forward_message_id
  end

  def record_export(user, method)
    raise ArgumentError.new('Export method must be one of screenshot, library, or other.') unless %w(screenshot library other).include?(method)

    now = Time.current.to_f
    export_json = {message_id: id, user_id: user.id, method: method, timestamp: now}.to_json

    if forward_message
      ancestor_ids = ancestor_message_ids.values

      redis.pipelined do
        [*ancestor_ids, id].each do |message_id|
          redis.rpush("message:#{message_id}:exports", export_json)
        end
      end
    else
      exports << export_json
    end
  end

  def meta_message?
    attachment_content_type.starts_with?('meta/')
  end

  def send_forward_meta_messages
    return if forward_message.nil?

    attrs = {attachment_content_type: 'meta/forward', actor_id: user.id}
    alert = "#{user.username} shared your #{message_attachment.media_type_name}"
    custom_data = {}

    [original_message, forward_message].uniq(&:id).each do |message|
      m = Message.new(attrs.merge(one_to_one_id: message.conversation.id, user_id: message.conversation.other_user_id(message.user),
                                  attachment_message_id: message.id))
      m.save

      message.user.mobile_notifier.create_ios_notifications(alert, custom_data)
    end
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
    errors.add(:base, "Either text or an attachment is required.") unless text.present? || attachment_file.present? ||
      attachment_url.present? || (forward_message && forward_message.attachment_url.present?) || meta_message?
  end

  def save_message_attachment
    if attachment_file.present?
      @message_attachment = MessageAttachment.new(message_id: id, message: self, attachment: attachment_file)
      @message_attachment.save!
    elsif attachment_url.present?
      @message_attachment = MessageAttachment.new(message_id: id, message: self, remote_attachment_url: attachment_url)
      @message_attachment.save!
    elsif forward_message_id.present? && !forward_message.meta_message?
      @message_attachment = MessageAttachment.new(message_id: id, message: self, remote_attachment_url: forward_message.attachment_url)
      @message_attachment.save!
    end
  end

  def write_attrs
    self.created_at = Time.current.to_i

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

    redis.multi do
      self.attrs.bulk_set(id: id, group_id: group_id, one_to_one_id: one_to_one_id, user_id: user_id,
                          text: text, mentioned_user_ids: @mentioned_user_ids, message_attachment_id: message_attachment_id,
                          attachment_url: attachment_url, attachment_content_type: attachment_content_type,
                          attachment_preview_url: attachment_preview_url, attachment_preview_width: attachment_preview_width,
                          attachment_preview_height: attachment_preview_height, attachment_metadata: attachment_metadata,
                          client_metadata: client_metadata, original_message_id: original_message_id, forward_message_id: forward_message_id,
                          actor_id: actor_id, attachment_message_id: attachment_message_id, created_at: created_at, expires_in: expires_in,
                          expires_at: expires_at)

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

  # Copy the parent's ancestor list and append the parent
  def set_ancestor_list
    return if forward_message.nil?

    redis.multi do
      redis.sort(forward_message.ancestor_message_ids.key, {by: 'nosort', store: ancestor_message_ids.key})
      ancestor_message_ids << forward_message.id
    end
  end

  def increment_forward_stats
    return if forward_message.nil?

    forward_json = {message_id: id, user_id: user.id, timestamp: Time.current.to_f}.to_json
    ancestor_ids = ancestor_message_ids.values

    redis.pipelined do
      ancestor_ids.each do |message_id|
        redis.rpush("message:#{message_id}:forwards", forward_json)
      end
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
    end
  end
end
