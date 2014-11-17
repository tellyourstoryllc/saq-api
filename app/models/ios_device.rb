class IosDevice < BaseDevice
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user

  after_save :remove_old_push_tokens, :check_uninstalls

  set :mixpanel_installed_device_ids, global: true
  value :existing_user_status # r = registered, s = sent event
  hash_key :content_push_info

  MIN_CLIENT_VERSIONS = {
    content_pushes: 206
  }


  def preferences
    @preferences ||= IosDevicePreferences.new(id: id)
  end

  def has_auth?
    push_token.present?
  end


  def current_content_frequency(loaded_user_frequency = nil, loaded_device_frequency = nil, loaded_unanswered_count = nil)
    user_frequency = loaded_user_frequency || user.content_frequency

    frequency = if user_frequency.blank?
                  nil
                elsif user_frequency.to_i == 0
                  0
                else
                  levels = ContentNotifier::CONTENT_FREQUENCIES[user_frequency]
                  count = (loaded_unanswered_count || unanswered_count).to_i

                  level = levels.detect do |l|
                    l[:unanswered_count].nil? || count < l[:unanswered_count]
                  end

                  level[:frequency]
                end

    content_push_info['current_frequency'] = frequency unless frequency.nil? || frequency == loaded_device_frequency
    frequency
  end

  def unanswered_count
    @unanswered_count ||= content_push_info['unanswered_count'].to_i
  end

  def reset_content_push_info
    content_push_info.bulk_set(current_frequency: user.try(:content_frequency), unanswered_count: 0)
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
