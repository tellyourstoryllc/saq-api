class MessageMailerDripNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(drip_notification_id, user_id)
    perform_with_tracking(drip_notification_id, user_id) do
      drip_notification = DripNotification.find(drip_notification_id)
      user = User.find(user_id)
      user.email_notifier.notify_drip!(drip_notification)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
