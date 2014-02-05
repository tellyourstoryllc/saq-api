class IosDevicePreferences < BaseDevicePreferences
  attr_accessor :ios_device_id
  hash_key :attrs

  validates :id, :ios_device_id, presence: true


  def initialize(attributes = {})
    super
    self.ios_device_id = id if id.present?
  end

  def attrs_to_write
    super.merge(ios_device_id: ios_device_id)
  end
end
