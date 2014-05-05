class BaseDevicePreferences
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :client, :server_mention, :server_one_to_one,
    :server_pushes_enabled, :created_at
  hash_key :attrs

  DEFAULTS = {
    server_one_to_one: true,
    server_mention: true,
    server_pushes_enabled: false
  }


  def initialize(attributes = {})
    super

    if id.present?
      to_int(:id, :created_at)
      to_bool(:server_mention, :server_one_to_one, :server_pushes_enabled)
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

  def server_pushes_enabled
    !@server_pushes_enabled.nil? ? @server_pushes_enabled : DEFAULTS[:server_pushes_enabled]
  end

  def attrs_to_write
    {client: client, server_mention: server_mention, server_one_to_one: server_one_to_one,
      server_pushes_enabled: server_pushes_enabled, created_at: created_at}
  end


  private

  def write_attrs
    to_bool(:server_mention, :server_one_to_one, :server_pushes_enabled)
    self.created_at ||= Time.current.to_i

    self.attrs.bulk_set(attrs_to_write)
  end
end
