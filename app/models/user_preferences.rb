class UserPreferences
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :user_id, :client_web, :server_mention_email,
    :server_one_to_one_email, :created_at
  hash_key :attrs

  validates :id, :user_id, presence: true

  DEFAULTS = {
    server_one_to_one_email: true,
    server_mention_email: true
  }


  def initialize(attributes = {})
    super

    if id.present?
      self.user_id = id
      to_int(:id, :created_at)
      to_bool(:server_mention_email, :server_one_to_one_email)
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


  private

  def write_attrs
    to_bool(:server_mention_email, :server_one_to_one_email)
    self.created_at ||= Time.current.to_i

    self.attrs.bulk_set(user_id: user_id, client_web: client_web, server_mention_email: server_mention_email,
                        server_one_to_one_email: server_one_to_one_email, created_at: created_at)
  end
end
