class ClientConfiguration < Settings
  include Redis::Objects
  hash_key :attrs, global: true

  def self.fetch_config
    hsh = attrs.all
    new_hsh = {}

    hsh.each do |k,v|
      new_hsh[k.gsub(PREFIX, '')] = v if k.starts_with?(PREFIX) && v != '_nil'
    end

    new_hsh
  end

  def self.config
    fetch_config
  end
end
