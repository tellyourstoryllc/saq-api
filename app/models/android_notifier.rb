class AndroidNotifier < MobileNotifier
  def build_notification(alert, custom_data = {})
    app = Rails.configuration.app['rapns']['android_app']
    attrs = {app: app, data: custom_data.merge(message: alert)}
    notification = Rapns::Apns::Notification.new(attrs)

    Rails.logger.debug "Notification: #{notification.inspect}; payload_size: #{notification.payload_size}"
    notification
  end
end
