class IosDevice < ActiveRecord::Base
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user


  def self.create_or_assign!(user, attrs)
    return if attrs[:device_id].blank?

    ios_device = where(device_id: attrs[:device_id]).first_or_initialize
    ios_device.update!(attrs.merge(user_id: user.id))
  end

  def unassign!
    update!(user_id: nil)
  end

  def preferences
    @preferences ||= IosDevicePreferences.new(id: id)
  end

  def notify?(user, conversation, message, notification_type)
    return false if push_token.blank?

    case notification_type
    when :one_to_one then preferences.server_one_to_one
    when :mention then preferences.server_mention || UserGroupPreferences.find(user, conversation).server_all_messages_mobile_push
    when :all then UserGroupPreferences.find(user, conversation).server_all_messages_mobile_push && under_limit?(user, conversation)
    end
  end

  def under_limit?(user, conversation)
    limit = 10.minutes
    last_push_at = user.last_group_pushes[conversation.id]

    if last_push_at.nil? || Time.zone.at(last_push_at.to_i) < limit.ago
      user.last_group_pushes[conversation.id] = Time.current.to_i
      true
    else
      false
    end
  end

  def notify_new_member?(user)
    push_token.present?
  end
end
