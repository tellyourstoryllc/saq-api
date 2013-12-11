class EmailNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(notification_type, message_id, user_id, status)
    perform_with_tracking(notification_type, message_id, user_id, status) do
      user = User.find(user_id)
      message = Message.new(id: message_id)
      EmailNotifier.new(user).notify!(notification_type, message, status)
    end
  end

  statsd_measure :perform, metric_prefix
end
