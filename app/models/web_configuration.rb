class WebConfiguration < ClientConfiguration
  include Redis::Objects
  hash_key :attrs, global: true

  def self.config
    ClientConfiguration.config.merge(attrs.all)
  end
end
