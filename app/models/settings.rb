class Settings
  include Redis::Objects

  hash_key :attrs, global: true
  FEATURES = [:queue]
  PREFIX = Rails.configuration.app['client']['config_prefix'] + '_'


  def self.get(key)
    val = attrs[PREFIX + key.to_s]
    val == '_nil' ? nil : val
  end

  def self.set(key, value)
    attrs[PREFIX + key.to_s] = value.nil? ? '_nil' : value
  end

  def self.delete(key)
    attrs.delete(PREFIX + key.to_s)
  end

  def self.feature_toggle_key(feature)
    "feature_#{feature}"
  end

  def self.enabled?(feature)
    get(feature_toggle_key(feature)) == '1'
  end

  def self.enable!(feature)
    set(feature_toggle_key(feature), '1')
  end

  def self.disable!(feature)
    set(feature_toggle_key(feature), '0')
  end

  def self.get_list(key)
    val = get(key)
    val = val.to_s.split(',')
    val
  end
end
