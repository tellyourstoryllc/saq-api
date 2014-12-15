class NonFriendStoriesList < StoriesList
  include Redis::Objects
  include Peanut::Conversation
  include Peanut::StoriesCollection
end
