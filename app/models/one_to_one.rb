class OneToOne
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::TwoUserConversation

  def save
    return unless valid?

    write_attrs
    add_to_lists
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

  def write_attrs
    self.created_at = Time.current.to_i
    self.attrs.bulk_set(id: id, created_at: created_at)
  end
end
