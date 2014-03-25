class IosConfiguration < ClientConfiguration
  include Redis::Objects
  hash_key :attrs, global: true

  def self.config
    ClientConfiguration.config.merge(fetch_config)
  end
end
