class UserPreferences
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :user_id, :client_web, :server_mention_email, :server_one_to_one_email,
    :server_story_privacy, :server_disable_story_comments, :created_at
  hash_key :attrs
  set :server_story_friends_to_block

  validates :id, :user_id, presence: true

  DEFAULTS = {
    server_one_to_one_email: true,
    server_mention_email: true,
    server_story_privacy: 'friends',
    server_disable_story_comments: false
  }

  STORY_PRIVACIES = %w(everyone friends custom)


  def initialize(attributes = {})
    super

    if id.present?
      self.user_id = id
      to_int(:id, :created_at)
      to_bool(:server_mention_email, :server_one_to_one_email, :server_disable_story_comments)
    end
  end

  def save
    return unless valid?
    write_attrs
    true
  end

  def server_mention_email
    !@server_mention_email.nil? ? @server_mention_email : DEFAULTS[:server_mention_email]
  end

  def server_one_to_one_email
    !@server_one_to_one_email.nil? ? @server_one_to_one_email : DEFAULTS[:server_one_to_one_email]
  end

  def server_story_privacy
    !@server_story_privacy.nil? ? @server_story_privacy : DEFAULTS[:server_story_privacy]
  end

  def server_story_privacy=(privacy)
    @server_story_privacy = privacy if STORY_PRIVACIES.include?(privacy)
  end

  def update_blocks(usernames)
    redis.multi do
      server_story_friends_to_block.del
      server_story_friends_to_block << usernames unless usernames.blank?
    end
  end

  def server_disable_story_comments
    !@server_disable_story_comments.nil? ? @server_disable_story_comments : DEFAULTS[:server_disable_story_comments]
  end


  private

  def write_attrs
    to_bool(:server_mention_email, :server_one_to_one_email, :server_disable_story_comments)
    self.created_at ||= Time.current.to_i

    self.attrs.bulk_set(user_id: user_id, client_web: client_web, server_mention_email: server_mention_email,
                        server_one_to_one_email: server_one_to_one_email,
                        server_story_privacy: server_story_privacy,
                        server_disable_story_comments: server_disable_story_comments, created_at: created_at)
  end
end
