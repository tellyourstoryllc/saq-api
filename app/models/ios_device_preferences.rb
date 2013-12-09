class IosDevicePreferences
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :ios_device_id, :client, :server_mention,
    :server_one_to_one, :created_at
  hash_key :attrs

  validates :id, :ios_device_id, presence: true

  DEFAULTS = {
    server_one_to_one: true,
    server_mention: true
  }


  def initialize(attributes = {})
    super

    if id.present?
      self.ios_device_id = id
      to_int(:id, :created_at)
      to_bool(:server_mention, :server_one_to_one)
    end
  end

  def save
    return unless valid?
    write_attrs
    true
  end

  def server_mention
    !@server_mention.nil? ? @server_mention : DEFAULTS[:server_mention]
  end

  def server_one_to_one
    !@server_one_to_one.nil? ? @server_one_to_one : DEFAULTS[:server_one_to_one]
  end


  private

  def write_attrs
    to_bool(:server_mention, :server_one_to_one)
    self.created_at ||= Time.current.to_i

    self.attrs.bulk_set(ios_device_id: ios_device_id, client: client, server_mention: server_mention,
                        server_one_to_one: server_one_to_one, created_at: created_at)
  end
end
