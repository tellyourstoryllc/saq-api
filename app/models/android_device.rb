class AndroidDevice < BaseDevice
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user

  after_save :remove_old_registration_ids

  set :mixpanel_installed_device_ids, global: true
  value :existing_user_status # r = registered, s = sent event


  def v=(version)
    self.client_version = version
  end

  def preferences
    @preferences ||= AndroidDevicePreferences.new(id: id)
  end

  def has_auth?
    registration_id.present?
  end

  def client
    'android'
  end


  private

  def remove_old_registration_ids
    AndroidDevice.where('id != ?', id).where(registration_id: registration_id).update_all(registration_id: nil) if registration_id.present?
  end
end
