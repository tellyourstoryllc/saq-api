class Settings
  include Redis::Objects

  hash_key :attrs, global: true
  FEATURES = [:queue]


  def self.get(key)
    val = attrs[key]
    val == '_nil' ? nil : val
  end

  def self.set(key, value)
    attrs[key] = value.nil? ? '_nil' : value
  end

  def self.delete(key)
    attrs.delete(key)
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
end
