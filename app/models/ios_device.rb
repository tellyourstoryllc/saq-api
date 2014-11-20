class IosDevice < BaseDevice
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user

  after_save :remove_old_push_tokens, :check_uninstalls

  set :mixpanel_installed_device_ids, global: true
  value :existing_user_status # r = registered, s = sent event
  hash_key :phone_verification_tokens, global: true

  MIN_CLIENT_VERSIONS = {
    all_server_notifications: 22060
  }


  def preferences
    @preferences ||= IosDevicePreferences.new(id: id)
  end

  def has_auth?
    push_token.present?
  end

  def client
    'ios'
  end

  def version_at_least?(feature)
    client_version.to_i >= MIN_CLIENT_VERSIONS[feature]
  end


  private

  def remove_old_push_tokens
    IosDevice.where('id != ?', id).where(push_token: push_token).update_all(push_token: nil) if push_token.present?
  end

  def check_uninstalls
    if !uninstalled_was && uninstalled && !user.ios_devices.where(uninstalled: false).exists? && user.android_devices.empty?
      user.update!(uninstalled: true)
    elsif uninstalled_was && !uninstalled
      user.update!(uninstalled: false)
    end
  end
end
