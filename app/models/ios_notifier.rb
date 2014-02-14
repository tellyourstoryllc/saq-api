class IosNotifier < MobileNotifier
  def build_notification(alert, custom_data = {})
    attrs = {app: Rails.configuration.app['rpush']['ios_app'], alert: alert, data: custom_data}
    notification = Rpush::Apns::Notification.new(attrs)
    Rails.logger.debug "Notification: #{notification.inspect}; payload_size: #{notification.payload_size}"

    # Truncate the alert if the total payload size is too big
    max_size = 256
    if notification.payload_size > max_size
      alert_size = notification.alert.size - (notification.payload_size - max_size)
      notification.alert = notification.alert.truncate(alert_size, {separator: ' '})
      Rails.logger.debug "Truncated payload_size: #{notification.payload_size}"
    end

    notification
  end
end
