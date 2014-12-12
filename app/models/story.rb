class Story < Message
  include Peanut::CommentsCollection

  validate :valid_permission?


  def initialize(attributes = {})
    super
    self.type = 'story'
  end

  def rank; end
  def self.redis_prefix; 'message' end

  # Disable some message functionality
  def forward_message_id=(*args); end
  def send_forward_meta_messages(*args); end
  def send_like_meta_messages(*args); end
  def send_export_meta_messages(*args); end

  # Permissions convenience methods
  def private?; story_permission == 'private' end
  def friends?; story_permission == 'friends' end
  def public?; story_permission == 'public' end


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

  def save
    # Default permission to private if not given
    self.story_permission ||= 'private'

    saved = super
    return unless saved

    user.update_last_public_story(self) if self.public?

    true
  end

  def update(update_attrs)
    update_attrs.each do |k, v|
      send("#{k}=", v)
    end

    # Update attachment overlay file and/or text
    overlay_file = update_attrs[:attachment_overlay_file]
    overlay_text = update_attrs[:attachment_overlay_text]
    update_message_attachment_overlay(overlay_file, overlay_text) if overlay_file.present?

    # Update simple attrs
    simple_attrs = update_attrs.slice(:latitude, :longitude, :source)
    attrs.bulk_set(simple_attrs) if simple_attrs.present?
    user.update_last_public_story(self) if self.public?

    true
  end

  # Add to the creator's stories list(s), depending on the story's permission
  def add_to_stories_lists
    non_friend_stories_list = NonFriendStoriesList.new(id: user.id)
    friend_stories_list = FriendStoriesList.new(id: user.id)
    my_stories_list = MyStoriesList.new(id: user.id)

    redis.pipelined do
      non_friend_stories_list.add_message(self) if public?
      friend_stories_list.add_message(self) if public? || friends?
      my_stories_list.add_message(self)
    end
  end

  def add_to_friend_feeds
    friend_ids = if public?
                   user.follower_ids.members
                 elsif friends?
                   user.mutual_friend_ids
                 else
                   []
                 end

    pushed_user_ids = []

    friend_ids.each do |friend_id|
      feed = FriendFeed.new(id: friend_id)
      added = feed.add_message(self)

      pushed_user_ids << friend_id if added
    end

    pushed_user_ids
  end

  # Push to the creator's stories list(s) and the relevant friend feeds
  def push_to_lists_and_feeds
    add_to_stories_lists
    pushed_user_ids = add_to_friend_feeds
    pushed_user_ids
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

  def in_users_feed?(current_user)
    StoriesFeed.new(user_id: current_user.id).message_ids.member?(id)
  end

  def comments_disabled?
    user.preferences.server_disable_story_comments
  end

  def can_create_comment?(current_user)
    in_users_feed?(current_user) && !comments_disabled?
  end

  def can_view_comments?(current_user)
    in_users_feed?(current_user)
  end

  def delete
    # TODO delete all its likes, exports, etc. to clean up and delete unused memory?
    attrs.del
  end

  def commenter_ids
    comment_prefix = Comment.redis_prefix
    ids = comment_ids.members

    redis.pipelined do
      ids.map{ |id| redis.hget("#{comment_prefix}:#{id}:attrs", :user_id) }
    end.uniq
  end


  private

  def text_or_attachment_set?
    errors.add(:base, "Either text or an attachment is required.") unless media_id_exists? || text.present? || attachment_file.present? ||
      attachment_url.present? || (forward_message && forward_message.attachment_url.present?) || meta_message?
  end

  def valid_permission?
    errors.add(:base, "Story permission must be one of 'private', 'friends', or 'public'.") unless %w(private friends public).include?(story_permission)
  end

  def add_snapchat_media_id
    user.redis.hsetnx(user.story_snapchat_media_ids.key, snapchat_media_id, id) if snapchat_media_id.present?
  end

  def increment_user_stats
    key = user.metrics.key
    user.redis.hincrby(key, :created_stories_count, 1)
  end

  def increment_stats
    StatsD.increment('stories.by_source.internal.sent') unless imported?

    # Was this a message that was fetched/imported from another service?
    sender_qualifier = imported? ? 'external' : 'internal'
    StatsD.increment("stories.by_source.#{sender_qualifier}.received")
  end
end
