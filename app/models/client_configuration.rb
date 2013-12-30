class ClientConfiguration < Settings
  include Redis::Objects
  hash_key :attrs, global: true

  def self.config
    attrs.all
  end
end
