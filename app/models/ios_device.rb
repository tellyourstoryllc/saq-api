class IosDevice < ActiveRecord::Base
  validates :device_id, :client_version, :os_version, presence: true
  validates :device_id, uniqueness: true

  belongs_to :user

  after_save :remove_old_push_tokens


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
    when :all then UserGroupPreferences.find(user, conversation).server_all_messages_mobile_push
    end
  end

  def notify_new_member?(user)
    push_token.present?
  end


  private

  def remove_old_push_tokens
    IosDevice.where('id != ?', id).where(push_token: push_token).update_all(push_token: nil) if push_token.present?
  end
end
