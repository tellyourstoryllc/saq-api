class MessageMailerWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(notification_type, user_id, message_id, data)
    perform_with_tracking(notification_type, user_id, message_id, data) do
      user = User.find(user_id)
      message = Message.new(id: message_id)
      user.email_notifier.send_snap_notification!(notification_type, message, data) if user.away_idle_or_unavailable?

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
