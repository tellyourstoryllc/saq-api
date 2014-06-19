class StoriesFeed
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::Conversation
  include Peanut::StoriesCollection

  attr_accessor :id, :user_id, :created_at

  def id=(new_id)
    @id = new_id
    @user_id = new_id
  end

  def user_id=(new_id)
    @id = new_id
    @user_id = new_id
  end

  def save
    return unless valid?

    write_attrs
  end


  private

  def write_attrs
    self.created_at ||= Time.current.to_i
    self.attrs.bulk_set(id: id, user_id: user_id, created_at: created_at)
  end
end
