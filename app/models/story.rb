class Story < Message
  def initialize(attributes = {})
    super
    self.type = 'story'
  end

  def rank; end
  def self.redis_prefix; 'message' end

  def add_to_stories_list_and_feed(other_user_id)
    stories_list = StoriesList.new(creator_id: user.id, viewer_id: other_user_id, fetched: true)
    return unless stories_list.save

    stories_feed = StoriesFeed.new(user_id: other_user_id, fetched: true)
    return unless stories_feed.save

    redis.pipelined do
      # Add to the friend's view of the creator's stories
      stories_list.add_message(self)

      # Add to the friend's feed
      stories_feed.add_message(self)
    end
  end

  # For each user who should be able to view this story,
  # according the the creator's current story preference,
  # push the story's ID to his feed and his view of the
  # creator's stories
  def push_to_feeds(current_user)
    user_ids = [user_id, current_user.id]

    # TODO contact_ids or snapchat_friend_ids
    user_ids += current_user.contact_ids.members if current_user.id == user_id

    user_ids.uniq.each do |friend_id|
      add_to_stories_list_and_feed(friend_id)
    end
  end
end
