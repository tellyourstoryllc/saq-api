class UserGroupPreferences
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :user_id, :group_id, :server_all_messages_mobile_push, :created_at
  hash_key :attrs

  validates :id, :user_id, :group_id, presence: true

  DEFAULTS = {
    server_all_messages_mobile_push: true
  }


  def initialize(attributes = {})
    super

    if id.present?
      self.user_id, self.group_id = id.split('-')
      to_int(:created_at)
      to_bool(:server_all_messages_mobile_push)
    end
  end

  def self.find(user, group)
    new(id: "#{user.id}-#{group.id}")
  end

  def save
    return unless valid?
    write_attrs
    true
  end

  def server_all_messages_mobile_push
    !@server_all_messages_mobile_push.nil? ? @server_all_messages_mobile_push : DEFAULTS[:server_all_messages_mobile_push]
  end


  private

  def write_attrs
    to_bool(:server_all_messages_mobile_push)
    self.created_at ||= Time.current.to_i

    self.attrs.bulk_set(user_id: user_id, group_id: group_id,
                        server_all_messages_mobile_push: server_all_messages_mobile_push, created_at: created_at)
  end
end
