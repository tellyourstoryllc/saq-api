rpush_config = Rails.configuration.app['rpush']

if Rpush::Apns::App && Rpush::Apns::App.table_exists? && !Rails.configuration.app['rpush']['ios_app']
  Rails.configuration.app['rpush']['ios_app'] = Rpush::Apns::App.find_by(name: rpush_config['db_ios_app_name'])
end

if Rpush::Gcm::App && Rpush::Gcm::App.table_exists? && !Rails.configuration.app['rpush']['android_app']
  Rails.configuration.app['rpush']['android_app'] = Rpush::Gcm::App.find_by(name: rpush_config['db_android_app_name'])
end

if Rails.configuration.app['rpush']['ios_app'].nil?
  Rails.logger.warn "WARN: Could not find Rpush app #{rpush_config['db_ios_app_name']}. iOS Push Notifications will not work."
end

if Rails.configuration.app['rpush']['android_app'].nil?
  Rails.logger.warn "WARN: Could not find Rpush app #{rpush_config['db_android_app_name']}. Android Push Notifications will not work."
end


# Rpush configuration. Options set here are overridden by command-line options.

Rpush.configure do |config|
  # Run in the foreground?
  # config.foreground = false

  # Frequency in seconds to check for new notifications.
  # config.push_poll = 2

  # Frequency in seconds to check for feedback
  # config.feedback_poll = 60

  # Disable APNs error checking after notification delivery.
  # config.check_for_errors = true

  # ActiveRecord notifications batch size.
  # config.batch_size = 100

  # Perform updates to the storage backend in batches to reduce IO.
  # config.batch_storage_updates = true

  # Path to write PID file. Relative to Rails root unless absolute.
  # config.pid_file = '/path/to/rpush.pid'

  # Define a custom logger.
  # config.logger = MyLogger.new

  # Set ActiveRecord logger to Rpush.logger.
  config.intercept_active_record_logger = true
end

Rpush.reflect do |on|
  # Called with a Rpush::Apns::Feedback instance when feedback is received
  # from the APNs that a notification has failed to be delivered.
  # Further notifications should not be sent to the device.
  on.apns_feedback do |feedback|
    Rpush.logger.info "(Rpush) Received feedback: #{feedback.inspect}"
  end

  # Called when a notification is queued internally for delivery.
  # The internal queue for each app runner can be inspected:
  #
  # Rpush::Daemon::AppRunner.runners.each do |app_id, runner|
  #   runner.app
  #   runner.queue_size
  # end
  #
  on.notification_enqueued do |notification|
    Rpush.logger.info "(Rpush) Notification enqueued: #{notification.inspect}"
  end

  # Called when a notification is successfully delivered.
  on.notification_delivered do |notification|
    Rpush.logger.info "(Rpush) Notification delivered: #{notification.inspect}"
  end

  # Called when notification delivery failed.
  # Call 'error_code' and 'error_description' on the notification for the cause.
  on.notification_failed do |notification|
    Rpush.logger.info "(Rpush) Notification delivery failed: #{notification.inspect}"
  end

  # Called when a notification will be retried at a later date.
  # Call 'deliver_after' on the notification for the next delivery date
  # and 'retries' for the number of times this notification has been retried.
  # on.notification_will_retry do |notification|
  # end

  # Called when a TCP connection is lost and will be reconnected.
  on.tcp_connection_lost do |app, error|
    Rpush.logger.info "(Rpush) TCP connection lost, will reconnect: #{app.inspect} | #{error.inspect}"
  end

  # Called for each recipient which successfully receives a notification. This
  # can occur more than once for the same notification when there are multiple
  # recipients.
  # on.gcm_delivered_to_recipient do |notification, registration_id|
  # end

  # Called for each recipient which fails to receive a notification. This
  # can occur more than once for the same notification when there are multiple
  # recipients. (do not handle invalid registration IDs here)
  # on.gcm_failed_to_recipient do |notification, error, registration_id|
  # end

  # Called when the GCM returns a canonical registration ID.
  # You will need to replace old_id with canonical_id in your records.
  # on.gcm_canonical_id do |old_id, canonical_id|
  # end

  # Called when an APNs certificate will expire within 1 month.
  # Implement on.error to catch errors raised when the certificate expires.
  # on.apns_certificate_will_expire do |app, expiration_time|
  # end

  # Called when an SSL certificate will expire within 1 month.
  # Implement on.error to catch errors raised when the certificate expires.
  # on.ssl_certificate_will_expire do |app, expiration_time|
  # end

  # Called when the ADM returns a canonical registration ID.
  # You will need to replace old_id with canonical_id in your records.
  # on.adm_canonical_id do |old_id, canonical_id|
  # end

  # Called when an exception is raised.
  on.error do |error|
    Rpush.logger.info "(Rpush) Exception: #{error.inspect}"
  end
end
