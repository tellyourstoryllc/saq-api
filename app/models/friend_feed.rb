class FriendFeed
  include Peanut::RedisModel
  include Redis::Objects
  include Peanut::Conversation
  include Peanut::StoriesCollection

  attr_accessor :id
  def no_attrs; true end
end
