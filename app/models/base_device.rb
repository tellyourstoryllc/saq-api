class BaseDevice < ActiveRecord::Base
  include Redis::Objects
  self.abstract_class = true

  def self.create_or_assign!(user, attrs)
    device_id = attrs.delete(:device_id) || attrs.delete(:android_id)
    return if device_id.blank?

    device = where(device_id: device_id).first_or_initialize
    device.update!(attrs.merge(user_id: user.id))
  end

  def unassign!
    update!(user_id: nil)
  end

  def notify?(user, conversation, message, notification_type)
    return false unless has_auth?
    preferences.server_one_to_one
  end

  def notify_new_member?(user)
    has_auth?
  end
end
