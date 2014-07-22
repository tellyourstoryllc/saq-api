class BaseDevice < ActiveRecord::Base
  include Redis::Objects
  self.abstract_class = true

  def self.create_or_assign!(user, attrs)
    device_id = attrs.delete(:device_id) || attrs.delete(:android_id)
    return if device_id.blank?

    device = where(device_id: device_id).first_or_initialize
    old_user_id = device.user_id
    attrs[:user_id] = user.id

    # If we get a request for a device that was previously
    # uninstalled, it must have since been reinstalled
    attrs[:uninstalled] = false

    result = device.update!(attrs)

    # If the device changes ownership to a different user,
    # delete the existing content push info
    new_user_id = device.user_id
    if new_user_id != old_user_id && device.respond_to?(:content_push_info)
      device.content_push_info.del
    end

    result
  end

  def unassign!
    update!(user_id: nil)
  end

  def notify?(user, conversation, message, notification_type)
    return false unless can_send?
    preferences.server_one_to_one
  end

  def can_send?
    !uninstalled? && has_auth? && preferences.server_pushes_enabled
  end

  def can_send_content_push?
    !uninstalled? && has_auth?
  end

  def notify_new_member?(user)
    can_send?
  end

  def lang=(new_lang)
    self[:lang] = new_lang.gsub('_', '-')
  end
end
