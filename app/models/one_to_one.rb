class OneToOne
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::TwoUserConversation

  attr_accessor :fetched_message_ids_count, :request_status

  validate :check_privacy


  def save
    return unless valid?

    write_attrs
    add_to_lists
  end

  def self.pipelined_find(ids)
    return [] if ids.blank?

    attrs = redis.pipelined do
      ids.map{ |id| redis.hgetall("#{redis_prefix}:#{id}:attrs") }
    end

    message_ids_counts = redis.pipelined do
      ids.map{ |id| redis.zcard("#{redis_prefix}:#{id}:message_ids") }
    end

    attrs.map.with_index do |attrs, i|
      new(attrs.merge(fetched: true, fetched_message_ids_count: message_ids_counts[i]))
    end
  end

  def add_to_lists
    redis.pipelined do
      sender.one_to_one_ids << id
      sender.one_to_one_user_ids << recipient.id

      recipient.one_to_one_ids << id
      recipient.one_to_one_user_ids << sender.id
    end
  end

  def remove_from_lists
    redis.pipelined do
      sender.one_to_one_ids.delete(id)
      sender.one_to_one_user_ids.delete(recipient.id)

      recipient.one_to_one_ids.delete(id)
      recipient.one_to_one_user_ids.delete(sender.id)
    end
  end

  def publish_one_to_one_message(message, current_user = nil, options = {})
    u = current_user || message.user
    faye_publisher = FayePublisher.new(u.token)

    data = MessageSerializer.new(message).as_json

    users = [recipient]
    users.unshift(sender) if ! options[:skip_sender]

    users.each do |user|
      faye_publisher.publish_one_to_one_message(user, data)
    end
  end

  def allowed_by_privacy?
    recip = other_user(creator)

    case recip.one_to_one_privacy
    when 'unblurred_public_story'
      !!creator.last_public_story_unblurred
    when 'avatar_image'
      !!creator.last_public_story_unblurred || creator.avatar_url.present?
    when 'anybody'
      true
    else
      false
    end
  end

  # 1-1 is pending if the other user initiated, the recipient's 1-1 privacy is avatar_image,
  # and the other user doesn't have an unblurred public story but he has an avatar image
  def pending?(current_user)
    request_status.blank? && creator_id && creator_id != current_user.id && current_user.one_to_one_privacy == 'avatar_image' &&
      !creator.last_public_story_unblurred && creator.avatar_url.present?
  end

  def request_status=(status)
    if viewer && request_status.blank? &&
      %w(approved denied).include?(status) && pending?(viewer)

      attrs[:request_status] = status

      # If the viewer denied the request, block the sender
      if status == 'denied'
        other_user = other_user(viewer)
        viewer.block(other_user)
      end
    end

    @request_status = status
  end


  private

  def not_blocked?
    errors.add(:base, "Sorry, you can't start a 1-1 conversation with that user.") if blocked?
  end

  def check_privacy
    errors.add(:base, "Sorry, that user's privacy does not allow you to start a 1-1 conversation with them.") unless allowed_by_privacy?
  end

  def write_attrs
    self.created_at = Time.current.to_i
    self.attrs.bulk_set(id: id, creator_id: creator_id, created_at: created_at, request_status: request_status)
  end
end
