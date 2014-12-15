class OneToOne
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::TwoUserConversation

  attr_accessor :fetched_message_ids_count

  validate :outgoing_friend_or_contact?


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


  private

  def not_blocked?
    errors.add(:base, "Sorry, you can't start a 1-1 conversation with that user.") if blocked?
  end

  def outgoing_friend_or_contact?
    return if [sender.id, recipient.id].include?(Robot.user.id)

    other_user = other_user(creator)
    errors.add(:base, "Sorry, you can't start a 1-1 conversation with that user.") unless creator.outgoing_friend_or_contact?(other_user)
  end

  def write_attrs
    self.created_at = Time.current.to_i
    self.attrs.bulk_set(id: id, creator_id: creator_id, created_at: created_at)
  end
end
