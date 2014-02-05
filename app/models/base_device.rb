class BaseDevice < ActiveRecord::Base
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

    case notification_type
    when :one_to_one then preferences.server_one_to_one
    when :mention then preferences.server_mention || UserGroupPreferences.find(user, conversation).server_all_messages_mobile_push
    when :all then UserGroupPreferences.find(user, conversation).server_all_messages_mobile_push
    end
  end

  def notify_new_member?(user)
    has_auth?
  end
end
