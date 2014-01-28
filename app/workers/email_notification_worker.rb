class EmailNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(notification_type, message_id, user_id, status)
    perform_with_tracking(notification_type, message_id, user_id, status) do
      user = User.find(user_id)
      message = Message.new(id: message_id)
      user.email_notifier.send_notification!(notification_type, message, status) if user.away_idle_or_unavailable?

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
