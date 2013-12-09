class IosNotifier
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def notify!(notification_type, message)
    notification_type = notification_type.to_sym
    custom_data = {}

    if notification_type == :mention
      mentioned_name = message.mentioned_all? ? '@all' : 'you'
      alert = "#{message.user.name} mentioned #{mentioned_name} in the room \"#{message.group.name}\""
      alert << ": #{message.text}" if message.text.present?
      custom_data[:gid] = message.group.id
    elsif notification_type == :one_to_one
      alert = message.text.present? ? "#{message.user.name}: #{message.text}" : "#{message.user.name} sent you a 1-1 message"
      custom_data[:oid] = message.one_to_one.id
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
      next if ios_device.push_token.blank? || !ios_device.preferences.send("server_#{notification_type}")

      n = notification.dup
      n.device_token = ios_device.push_token
      n.save!
    end
  end
end
