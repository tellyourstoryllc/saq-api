class Story < Message
  def initialize(attributes = {})
    super
    self.type = 'story'
  end

  def rank; end
  def self.redis_prefix; 'message' end

  def self.media_id_exists?(user, snapchat_media_id)
    user.story_snapchat_media_ids.include?(snapchat_media_id)
  end

  def media_id_exists?
    self.class.media_id_exists?(user, snapchat_media_id)
  end

  def self.find_or_create(attrs)
    story = new(attrs)
    existing_story_id = story.user.story_snapchat_media_ids[story.snapchat_media_id]

    if existing_story_id
      new(id: existing_story_id)
    else
      story if story.save
    end
  end

  def add_to_stories_list_and_feed(other_user_id)
    stories_list = StoriesList.new(creator_id: user.id, viewer_id: other_user_id)
    return unless stories_list.save

    stories_feed = StoriesFeed.new(user_id: other_user_id)
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

  def self.existing_snapchat_media_ids(story_usernames, snapchat_media_ids)
    raise ArgumentError.new('story_usernames and snapchat_media_ids must be the same size.') if story_usernames.size != snapchat_media_ids.size

    users = User.select(:id, :username).where(username: story_usernames).to_a

    results = redis.pipelined do
      story_usernames.each_with_index do |username, i|
        user = users.detect{ |u| u.username == username }
        next if user.nil?

        user.story_snapchat_media_ids.include?(snapchat_media_ids[i])
      end
    end

    results.map.with_index do |exists, i|
      snapchat_media_ids[i] if exists
    end.compact
  end


  private

  def text_or_attachment_set?
    errors.add(:base, "Either text or an attachment is required.") unless media_id_exists? || text.present? || attachment_file.present? ||
      attachment_url.present? || (forward_message && forward_message.attachment_url.present?) || meta_message?
  end

  def add_snapchat_media_id
    user.redis.hsetnx(user.story_snapchat_media_ids.key, snapchat_media_id, id) if snapchat_media_id.present?
  end
end
