class IosDevice < BaseDevice
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user

  after_save :remove_old_push_tokens

  set :mixpanel_installed_device_ids, global: true


  def preferences
    @preferences ||= IosDevicePreferences.new(id: id)
  end

  def has_auth?
    push_token.present?
  end


  private

  def remove_old_push_tokens
    IosDevice.where('id != ?', id).where(push_token: push_token).update_all(push_token: nil) if push_token.present?
  end
end
