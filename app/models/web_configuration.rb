class WebConfiguration < ClientConfiguration
  include Redis::Objects
  hash_key :attrs, global: true

  def self.config
    ClientConfiguration.config.merge(attrs.all).reject{ |k,v| v == '_nil' }
  end
end
