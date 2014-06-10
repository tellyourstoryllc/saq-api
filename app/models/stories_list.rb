class StoriesList
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::TwoUserConversation

  def save
    return unless valid?

    write_attrs
  end


  private

  def not_blocked?
    errors.add(:base, "Sorry, you can't see that user's stories.") if blocked?
  end

  def write_attrs
    self.created_at = Time.current.to_i
    self.attrs.bulk_set(id: id, created_at: created_at)
  end
end
