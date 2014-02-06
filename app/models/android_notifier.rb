class AndroidNotifier < MobileNotifier
  def build_notification(alert, custom_data = {})
    app = Rails.configuration.app['rapns']['android_app']
    attrs = custom_data.merge(app: app, data: {message: alert})
    notification = Rapns::Apns::Notification.new(attrs)

    Rails.logger.debug "Notification: #{notification.inspect}; payload_size: #{notification.payload_size}"
    notification
  end
end
