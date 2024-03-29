class Story < Message
  include Peanut::CommentsCollection
  include Peanut::Flaggable
  include Peanut::SubmittedForYourApproval
  include Peanut::Search

  validate :valid_permission?

  # For some reason, this isn't inherited from Message > Peanut::Search
  index_name Rails.configuration.app['app_name_short'].downcase

  # Define fields we want searchable in Elasticsearch, and how they're analyzed
  #mappings dynamic: 'false' do
  #  indexes :id, type: 'string', index: 'no'
  #  indexes :created_at, type: 'date', format: 'date_time_no_millis'
  #  indexes :permission, type: 'string', index: 'not_analyzed'
  #  indexes :source, type: 'string', index: 'not_analyzed'
  #  indexes :status, type: 'string', index: 'not_analyzed'
  #  indexes :has_face, type: 'boolean', index: 'not_analyzed'
  #  indexes :tags, type: 'string', analyzer: 'english'
  #end


  def initialize(attributes = {})
    super
    self.type = 'story'
  end

  def rank; end
  def self.redis_prefix; 'message' end

  # Disable some message functionality
  #def forward_message_id=(*args); end
  def send_forward_meta_messages(*args); end
  def send_like_meta_messages(*args); end
  def send_export_meta_messages(*args); end

  # Permissions convenience methods
  def private?; permission == 'private' end
  def friends?; permission == 'friends' end
  def public?; permission == 'public' end

  def shareable_to_anywhere?; shareable_to == 'anywhere' end
  def shareable_to_youtube?; shareable_to_anywhere? || shareable_to == 'youtube' end


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

  def deleted?
    !attrs.exists?
  end

  def has_face=(val)
    @has_face = val if %w(yes no unknown).include?(val)
  end

  def allowed_permission?
    %w(private friends public).include?(permission)
  end

  def save
    # Default permission to private if not given
    self.permission ||= 'private'

    saved = super
    return unless saved

    check_censor_level
    user.update_last_public_story(self)
    #index_on_elasticsearch

    true
  end

  def allowed_in_public_feed?
    #public? && !review? && !censored? && source == 'camera' && has_face == 'yes' && !deleted?
    public? && !review? && !censored? && source == 'camera' && !deleted?
  end

  def has_permission?(viewer)
    public? ||
      (private? && viewer.id == user_id) ||
      (friends? && (viewer.id == user_id || viewer.fetched_follower_ids.member?(user_id)))
  end

  # Update the user's last public story attrs if this was the last public
  # story but it's been changed to friends or private
  def check_last_public_story
    return unless (user.last_public_story_id == id && !allowed_in_public_feed?) ||
      (user.last_public_story_id != id && allowed_in_public_feed?)

    # Get the next most recent public story that's allowed in the public feed, if there is one
    stories = NonFriendStoriesList.new(id: user.id).paginate_messages(limit: 20)
    story = stories.reverse.detect{ |story| story.allowed_in_public_feed? }
    user.update_last_public_story(story, true)
  end

  # If changing to private:
  # Remove from my followers' feeds
  # Remove from my FriendStoriesList (and NonFriendStoriesList if changing from public)
  def change_to_private(old_permission)
    friend_ids = user.follower_ids.members
    delete_from_friend_feeds(friend_ids)

    FriendStoriesList.new(id: user.id).message_ids.delete(id)

    if old_permission == 'public'
      NonFriendStoriesList.new(id: user.id).message_ids.delete(id)
      check_last_public_story
    end
  end

  # If changing to friends:
  def change_to_friends(old_permission)
    # From private:
    # Add to my mutual friends' feeds
    # Add to my FriendStoriesList
    if old_permission == 'private'
      friend_ids = user.mutual_friend_ids
      pushed_user_ids = add_to_friend_feeds(friend_ids)

      FriendStoriesList.new(id: user.id).add_message(self)

    # From public:
    # Remove from the feeds of my followers who I haven't added back
    # Remove from my NonFriendStoriesList
    elsif old_permission == 'public'
      friend_ids = user.follower_ids - user.friend_ids
      delete_from_friend_feeds(friend_ids)

      NonFriendStoriesList.new(id: user.id).message_ids.delete(id)

      check_last_public_story
    end

    pushed_user_ids
  end

  # If changing to public:
  def change_to_public(old_permission)
    # From private:
    # Add to my followers' feeds
    # Add to my FriendStoriesList and NonFriendStoriesList
    if old_permission == 'private'
      friend_ids = user.follower_ids.members
      pushed_user_ids = add_to_friend_feeds(friend_ids)

      FriendStoriesList.new(id: user.id).add_message(self)
      NonFriendStoriesList.new(id: user.id).add_message(self)

    # From friends:
    # Add to the feeds of my followers who I haven't added back
    # Add to my NonFriendStoriesList
    elsif old_permission == 'friends'
      friend_ids = user.follower_ids - user.friend_ids
      pushed_user_ids = add_to_friend_feeds(friend_ids)

      NonFriendStoriesList.new(id: user.id).add_message(self)
    end

    check_last_public_story
    pushed_user_ids
  end

  def update_permission(new_permission)
    return if new_permission.blank? || new_permission == permission

    old_permission = permission
    self.permission = new_permission

    if !allowed_permission?
      self.permission = old_permission
      return
    end

    attrs[:permission] = permission

    # Return pushed user ids from the change_to_* methods
    if private?
      change_to_private(old_permission)
    elsif friends?
      change_to_friends(old_permission)
    elsif public?
      change_to_public(old_permission)
    end
  end

  def update(update_attrs)
    permission = update_attrs.delete(:permission)
    update_attrs.delete(:shareable_to) unless %w(nowhere youtube anywhere).include?(update_attrs[:shareable_to])
    @old_shareable_to = shareable_to

    update_attrs.each do |k, v|
      send("#{k}=", v)
    end

    # Update attachment overlay file and/or text
    overlay_file = update_attrs[:attachment_overlay_file]
    overlay_text = update_attrs[:attachment_overlay_text]
    update_message_attachment_overlay(overlay_file, overlay_text) if overlay_file.present?

    # Update simple attrs
    simple_attrs = update_attrs.slice(:latitude, :longitude, :has_face, :shareable_to)
    attrs.bulk_set(simple_attrs) if simple_attrs.present?

    # Update permission
    pushed_user_ids = update_permission(permission)

    create_and_upload_youtube_video
    update_youtube_video
    index_on_elasticsearch

    pushed_user_ids
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

  # Add its id to the FriendFeeds of the given friends, unless it's already there
  def add_to_friend_feeds(friend_ids = nil)
    # If friend_ids is not given (i.e. this is the first time setting the permission),
    # add it to the default friend ids for the permission
    friend_ids ||= if public?
                     user.follower_ids.members
                   elsif friends?
                     user.mutual_friend_ids
                   else
                     []
                   end

    pushed_user_ids = []

    results = redis.pipelined do
      friend_ids.each do |friend_id|
        feed = FriendFeed.new(id: friend_id)
        feed.add_message(self)
      end
    end

    results.each_with_index do |added, i|
      pushed_user_ids << friend_ids[i] if added
    end

    pushed_user_ids
  end

  # Delete its id from the FriendFeeds of the given friends
  def delete_from_friend_feeds(friend_ids)
    redis.pipelined do
      friend_ids.each do |friend_id|
        feed = FriendFeed.new(id: friend_id)
        feed.message_ids.delete(id)
      end
    end
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

    friend_ids = user.follower_ids.members
    delete_from_friend_feeds(friend_ids)

    NonFriendStoriesList.new(id: user.id).message_ids.delete(id)
    FriendStoriesList.new(id: user.id).message_ids.delete(id)
    MyStoriesList.new(id: user.id).message_ids.delete(id)

    Message.recent_story_ids.delete(id)
    delete_from_elasticsearch
    delete_from_youtube

    attrs.del

    check_last_public_story
    delete_from_moderator
  end

  def commenter_ids
    comment_prefix = Comment.redis_prefix
    ids = comment_ids.members

    redis.pipelined do
      ids.map{ |id| redis.hget("#{comment_prefix}:#{id}:attrs", :user_id) }
    end.uniq
  end

  def pending?
    status.blank? || super
  end

  def submit_to_moderator?
    has_attachment? && super
  end

  def review!
    attrs['status'] = self.status = 'review'
    check_last_public_story
    update_on_elasticsearch(status: status)
  end

  def approve!
    attrs['status'] = self.status = 'normal'
    check_last_public_story
    add_to_recents
    update_on_elasticsearch(status: status)
    create_and_upload_youtube_video
  end

  def censor!
    attrs['status'] = self.status = 'censored'
    check_last_public_story
    add_censored_object
    increment_flags_censored
    update_on_elasticsearch(status: status)
  end

  def tags
    text = attachment_overlay_text
    text.present? ? text.scan(/#([\w-]+)/).flatten : []
  end

  def as_indexed_json(options = {})
    StorySearchSerializer.new(self).as_json
  end

  def self.search_by_tag(tag, search_options = {})
    request = {
      query: {
        filtered: {
          filter: {
            bool: {
              must: [
                {term: {permission: 'public'}},
                {term: {source: 'camera'}},
                {term: {has_face: true}}
              ],
              must_not: [
                {terms: {status: %w(review censored)}}
              ]
            }
          },

          query: {
            match: {
              tags: tag
            }
          }
        }
      }
    }

    options = {}
    options[:size] = (search_options[:limit].presence || 20).to_i
    options[:size] = 1 if options[:size] <= 0
    options[:size] = 200 if options[:size] > 200
    options[:from] = search_options[:offset].to_i

    # Set a hard cap of 1000 total results through paging,
    # since performance can suffer due to the shards being distributed
    total = options[:size] + options[:from]
    options[:size] = [1000 - options[:from], 0].max if total > 1000

    # Send request to Elasticsearch
    results = search(request, options)

    story_ids = results.map(&:_id)
    return [] if story_ids.empty?

    stories = Story.pipelined_find(story_ids)
    users = User.includes(:account, :avatar_image, :avatar_video).where(id: stories.map(&:user_id).uniq)

    stories + users
  end

  def set_moderation_uuid(uuid)
    self.attrs['moderation_uuid'] = uuid
  end

  def delete_youtube_lock_key
    redis.del(youtube_lock_key)
  end


  private

  def text_or_attachment_set?
    errors.add(:base, "Either text or an attachment is required.") unless media_id_exists? || text.present? || attachment_file.present? ||
      attachment_url.present? || (forward_message && forward_message.attachment_url.present?) || meta_message?
  end

  def valid_permission?
    errors.add(:base, "Story permission must be one of 'private', 'friends', or 'public'.") unless allowed_permission?
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

  def moderation_description
    "#{self.user.username} (#{Rails.env}): #{self.class.name} #{self.id}"
  end

  def moderation_url
    attachment_url
  end

  def moderation_type
    message_attachment.media_type == 'video' ? :video : :photo
  end

  def check_censor_level
    if user.censor_critical?
      auto_censor!
    #elsif user.censor_warning?
    else
      submit_to_moderator
    end
  end

  def add_to_recents
    Message.recent_story_ids[id] = Time.current.to_i
  end

  def youtube_lock_key
    "message:#{id}:youtube_lock_key"
  end

  # Create video with branding and upload to Youtube using their API
  def create_and_upload_youtube_video
    return unless youtube_id.blank? && public? && !review? && !censored? && !blurred && shareable_to_youtube?

    locked = redis.set(youtube_lock_key, Time.current.to_f, {nx: true})

    unless locked
      Rails.logger.warn("Failed to obtain YouTube lock for story #{id}")
      return
    end

    youtube = YouTubeStoryUploader.new(self)
    youtube.create
  end

  def update_youtube_video
    return if youtube_id.blank?

    privacy = if %w(youtube anywhere).include?(@old_shareable_to) && !shareable_to_youtube?
                'private'
              elsif @old_shareable_to == 'nowhere' && shareable_to_youtube?
                'public'
              end

    return if privacy.nil?

    youtube = YouTubeStoryUploader.new(self)
    youtube.update(privacy: privacy)
  end

  def index_on_elasticsearch
    ES.index(self)
  end

  def update_on_elasticsearch(update_attrs)
    ES.update_attributes(self, update_attrs)
  end

  def delete_from_elasticsearch
    ES.delete(self)
  end

  def delete_from_youtube
    YouTubeStoryUploader.new.delete(youtube_id)
  end
end
