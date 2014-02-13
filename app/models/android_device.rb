class AndroidDevice < BaseDevice
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user


  def v=(version)
    self.client_version = version
  end

  def preferences
    @preferences ||= AndroidDevicePreferences.new(id: id)
  end

  def has_auth?
    registration_id.present?
  end
end
