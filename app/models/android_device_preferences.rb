class AndroidDevicePreferences < BaseDevicePreferences
  attr_accessor :android_device_id
  hash_key :attrs

  validates :id, :android_device_id, presence: true


  def initialize(attributes = {})
    super
    self.android_device_id = id if id.present?
  end

  # On Android, the client can't determine if the user
  # has disabled push notifications
  def server_pushes_enabled
    true
  end

  def attrs_to_write
    super.merge(android_device_id: android_device_id)
  end
end
