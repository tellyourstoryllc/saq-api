class Message
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :group_id, :one_to_one_id, :stories_list_id, :user_id, :rank, :text, :attachment_file,
    :mentioned_user_ids, :message_attachment_id, :attachment_url, :attachment_content_type,
    :attachment_preview_url, :attachment_preview_width, :attachment_preview_height,
    :attachment_metadata, :client_metadata, :received, :original_message_id, :forward_message_id,
    :actor_id, :attachment_message_id, :type, :snapchat_media_id, :created_at, :expires_in, :expires_at,
    :cached_likes_count, :cached_forwards_count

  hash_key :attrs
  list :ancestor_message_ids
  list :forwards # JSON strings for each forward on this or any forwarded/decendant messages (all levels deep)
  sorted_set :liker_ids # User IDs who have liked this specific message
  list :likes # JSON strings for each like on this or any forwarded/decendant messages (all levels deep)
  list :exports # JSON strings for each export on this or any forwarded/decendant messages (all levels deep)

  validates :user_id, presence: true
  validate :conversation_id?, :blacklisted_recipient?, :not_blocked?, :text_under_limit?, :text_or_attachment_set?

  TEXT_LIMIT = 1_000


  def initialize(attributes = {})
    super

    if id.present?
      to_int(:rank, :attachment_preview_width, :attachment_preview_height, :created_at, :expires_in, :expires_at)
      to_bool(:received)
    end
  end

  def self.pipelined_find(ids)
    return [] if ids.blank?

    attrs = redis.pipelined do
      ids.map{ |id| redis.hgetall("#{redis_prefix}:#{id}:attrs") }
    end

    likes_counts = redis.pipelined do
      ids.map{ |id| redis.llen("#{redis_prefix}:#{id}:likes") }
    end

    forwards_counts = redis.pipelined do
      ids.map{ |id| redis.llen("#{redis_prefix}:#{id}:forwards") }
    end

    messages = attrs.map.with_index do |attrs, i|
      new(attrs.merge(fetched: true, cached_likes_count: likes_counts[i], cached_forwards_count: forwards_counts[i]))
    end
  end

  def story?
    type == 'story'
  end

  def save
    return unless valid?

    generate_id
    sanitize_mentioned_user_ids
    save_message_attachment

    redis.multi do
      write_attrs
      add_snapchat_media_id if story?
      add_to_conversation
    end

    set_ancestor_list
    increment_forward_stats
    increment_unviewed_list
    increment_user_stats
    increment_cohort_stats
    increment_stats

    true
  end

  def rank
    @rank ||= attrs[:rank].to_i unless story?
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

  def stories_list
    @stories_list ||= StoriesList.new(id: stories_list_id) if stories_list_id
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
    return false if meta_message? || liker_ids.member?(user.id)

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

    true
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
    one_to_one || stories_list || group
  end

  def has_attachment?
    attachment_preview_url.present?
  end

  def original_message
    @original_message ||= Message.new(id: original_message_id) if original_message_id
  end

  def forward_message
    @forward_message ||= Message.new(id: forward_message_id) if forward_message_id
  end

  def record_export(user, method)
    self.class.raise_if_invalid_method(method)

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

    true
  end

  def self.raise_if_invalid_method(method)
    raise ArgumentError.new('Export method must be one of screenshot, library, or other.') unless %w(screenshot library other).include?(method)
  end

  def meta_message?
    attachment_content_type.present? && attachment_content_type.starts_with?('meta/')
  end

  def send_forward_meta_messages
    return if forward_message.nil?

    attrs = {attachment_content_type: 'meta/forward', actor_id: user.id}

    [original_message, forward_message].uniq(&:id).each do |message|
      m = Message.new(attrs.merge(one_to_one_id: message.conversation.id, user_id: message.conversation.other_user_id(message.user),
                                  attachment_message_id: message.id))
      m.save

      message.conversation.publish_one_to_one_message(m)
      message.user.send_forward_notifications(message, user)
    end
  end

  def send_like_meta_messages(current_user)
    attrs = {attachment_content_type: 'meta/like', actor_id: current_user.id}

    [original_message, self].compact.uniq(&:id).each do |message|
      m = Message.new(attrs.merge(one_to_one_id: message.conversation.id, user_id: message.conversation.other_user_id(message.user),
                                  attachment_message_id: message.id))
      m.save

      message.conversation.publish_one_to_one_message(m)
      message.user.send_like_notifications(message, current_user)
    end
  end

  def send_export_meta_messages(current_user, method)
    self.class.raise_if_invalid_method(method)

    attrs = {attachment_content_type: 'meta/export', actor_id: current_user.id}

    [original_message, self].compact.uniq(&:id).each do |message|
      m = Message.new(attrs.merge(one_to_one_id: message.conversation.id, user_id: message.conversation.other_user_id(message.user),
                                  attachment_message_id: message.id))
      m.save

      message.conversation.publish_one_to_one_message(m)
      message.user.send_export_notifications(message, current_user, method)
    end
  end

  def sent_externally?
    !received.nil?
  end

  def deleted?
    attrs[:attachment_content_type] == 'meta/delete'
  end

  def delete(current_user)
    return if deleted?

    # TODO delete all its likes, exports, etc. to clean up and delete unused memory?
    media_type = message_attachment.try(:media_type_name) || 'message'

    self.attrs.bulk_set(attachment_content_type: 'meta/delete',
                        attachment_metadata: {deleted_at: Time.current.to_i}.to_json,
                        actor_id: current_user.id, text: "[This #{media_type} has been deleted]",
                        message_attachment_id: nil, attachment_url: nil,
                        attachment_preview_url: nil, attachment_preview_width: nil,
                        attachment_preview_height: nil, attachment_message_id: nil)
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

  def conversation_id?
    convo_ids = [group_id, one_to_one_id, stories_list_id]
    errors.add(:base, "Must specify exactly one of group_id, one_to_one_id, or stories_list_id.") unless convo_ids.count(&:present?) == 1
  end

  def blacklisted_recipient?
    recipient = conversation.other_user(user) if conversation && conversation.respond_to?(:other_user)
    return if recipient.nil?

    errors.add(:base, "Sorry, that user is not available.") if User::BLACKLISTED_USERNAMES.include?(recipient.username)
  end

  def not_blocked?
    errors.add(:base, "Sorry, you can't message that user.") if conversation && conversation.respond_to?(:blocked?) && conversation.try(:blocked?)
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
    self.created_at ||= Time.current
    self.created_at = created_at.to_i
    to_bool(:received)

    if expires_in.present?
      self.expires_in = expires_in.to_i
      self.expires_at = (Time.current + expires_in).to_i
    end

    if @message_attachment && @message_attachment.attachment.present?
      # HACK: For duplicate attachments that weren't uploaded, the URL is still
      # set to the tmp file path. So we need to reload the model to get the S3 URL.
      if @message_attachment.attachment.url.include?('tmp')
        @message_attachment = MessageAttachment.find_by(id: @message_attachment.id)
      end

      self.attachment_url = @message_attachment.attachment.url
      self.attachment_content_type = @message_attachment.content_type
      self.attachment_preview_url = @message_attachment.preview_url
      self.attachment_preview_width = @message_attachment.preview_width
      self.attachment_preview_height = @message_attachment.preview_height
      self.message_attachment_id = @message_attachment.id
    end

    # If this message was received, change the sender
    if received && !story?
      self.user_id = one_to_one.other_user_id(user)
      @user = nil # Clear memoizer
    end

    redis.multi do
      self.attrs.bulk_set(id: id, group_id: group_id, one_to_one_id: one_to_one_id, user_id: user_id,
                          text: text, mentioned_user_ids: @mentioned_user_ids, message_attachment_id: message_attachment_id,
                          attachment_url: attachment_url, attachment_content_type: attachment_content_type,
                          attachment_preview_url: attachment_preview_url, attachment_preview_width: attachment_preview_width,
                          attachment_preview_height: attachment_preview_height, attachment_metadata: attachment_metadata,
                          client_metadata: client_metadata, received: received, original_message_id: original_message_id,
                          forward_message_id: forward_message_id, actor_id: actor_id, attachment_message_id: attachment_message_id,
                          type: type, snapchat_media_id: snapchat_media_id, created_at: created_at, expires_in: expires_in,
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
    convo.add_message(self) if convo
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

  def increment_unviewed_list
    return unless one_to_one

    recipient = one_to_one.other_user(user)
    return if user.bot? || recipient.bot? || recipient.id == user.id ||
      !recipient.account.registered?

    today = Time.zone.today

    user.redis.multi do
      recipient.unviewed_message_ids[id] = created_at
      User.unviewed_message_user_ids << recipient.id
    end
  end

  def increment_user_stats
    return unless group || one_to_one

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
        recipient = one_to_one.other_user(user)

        user.redis.hincrby(key, :sent_one_to_one_messages_count, 1) if user.bot? || !recipient.bot?

        if recipient.bot? || !user.bot?
          recipient_key = recipient.metrics.key
          user.redis.hincrby(recipient_key, :received_one_to_one_messages_count, 1)
          user.redis.hincrby(recipient_key, :received_messages_count, 1)
        end
      end

      user.redis.hincrby(key, :sent_messages_count, 1)
    end
  end

  def increment_cohort_stats
    return unless one_to_one

    recipient = one_to_one.other_user(user)
    today = Time.find_zone(User::COHORT_METRICS_TIME_ZONE).today.to_s

    # Skip metrics if either user is our bot
    return if user.bot? || recipient.bot?

    user.redis.pipelined do
      sender_key = user.cohort_metrics_key
      if sender_key
        field = ('sent_to_' + (recipient.account.registered? ? 'registered' : 'unregistered') + "_#{today}").to_sym
        user.redis.hincrby(sender_key, field, 1)
      end

      recipient_key = recipient.cohort_metrics_key
      if recipient_key
        field = ('received_from_' + (user.account.registered? ? 'registered' : 'unregistered') + "_#{today}").to_sym
        user.redis.hincrby(recipient_key, field, 1)
      end
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

      # Separate metrics if either user is our bot
      if recipient.bot?
        StatsD.increment("messages.one_to_one.by_user_type.bot.received")
      elsif !user.bot?
        unless sent_externally?
          registered_qualifier = recipient.account.registered? ? 'registered' : 'nonregistered'
          StatsD.increment("messages.one_to_one.#{registered_qualifier}.sent")
          StatsD.increment("messages.one_to_one.#{registered_qualifier}.received")
        end

        if recipient.account.registered?
          # Was this a message that was fetched/imported from another service?
          sender_qualifier = sent_externally? ? 'external' : 'internal'
          StatsD.increment("messages.one_to_one.by_source.#{sender_qualifier}.sent")
          StatsD.increment("messages.one_to_one.by_source.#{sender_qualifier}.received")
        end
      end
    end
  end
end
