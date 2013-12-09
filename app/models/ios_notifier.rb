class IosNotifier
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def notify!(message)
    convo = message.conversation
    custom_data = {}

    if convo.is_a?(Group)
      notification_type = message.mentioned?(user) ? :mention : :all
      custom_data[:gid] = convo.id
    elsif convo.is_a?(OneToOne)
      notification_type = :one_to_one
      custom_data[:oid] = convo.id
    end

    if notification_type == :mention
      mentioned_name = message.mentioned_all? ? '@all' : 'you'
      alert = "#{message.user.name} mentioned #{mentioned_name} in the room \"#{message.group.name}\""
      alert << ": #{message.text}" if message.text.present?
    elsif notification_type == :one_to_one
      alert = message.text.present? ? "#{message.user.name}: #{message.text}" : "#{message.user.name} sent you a 1-1 message"
    elsif notification_type == :all
      alert = message.text.present? ? "(#{message.group.name}) #{message.user.name}: #{message.text}" : "#{message.user.name} sent a message in the room \"#{message.group.name}\""
    end

    attrs = {app: Rails.configuration.app['rapns']['app'], alert: alert, data: custom_data}
    notification = Rapns::Apns::Notification.new(attrs)
    Rails.logger.debug "Notification: #{notification}; payload_size: #{notification.payload_size}"

    # Truncate the alert if the total payload size is too big
    max_size = 256
    if notification.payload_size > max_size
      alert_size = notification.alert.size - (notification.payload_size - max_size)
      notification.alert = notification.alert.truncate(alert_size, {separator: ' '})
      Rails.logger.debug "Truncated payload_size: #{notification.payload_size}"
    end

    user.ios_devices.each do |ios_device|
      next if ios_device.push_token.blank?

      enabled_in_prefs = case notification_type
                         when :one_to_one then ios_device.preferences.server_one_to_one
                         when :mention then ios_device.preferences.server_mention || UserGroupPreferences.find(user, convo).server_all_messages_mobile_push
                         when :all then UserGroupPreferences.find(user, convo).server_all_messages_mobile_push
                         end

      next unless enabled_in_prefs

      n = notification.dup
      n.device_token = ios_device.push_token
      n.save!
    end
  end
end
