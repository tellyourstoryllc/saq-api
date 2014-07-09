class AndroidNotifier < MobileNotifier
  def build_notification(alert, custom_data = {}, options = {})
    app = Rails.configuration.app['rpush']['android_app']
    attrs = options.merge(app: app, data: custom_data.merge(message: alert))
    notification = Rpush::Gcm::Notification.new(attrs)

    Rails.logger.debug "Notification: #{notification.inspect}; payload_size: #{notification.payload_size}"
    notification
  end
end
