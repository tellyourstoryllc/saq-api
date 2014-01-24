class MobileDigestNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :mobile_digest end

  def perform(user_id, message_id)
    perform_with_tracking(user_id, message_id) do
      user = User.find(user_id)
      message = Message.new(id: message_id)
      user.ios_notifier.send_notification(message, :all) if user.away_idle_or_unavailable?
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
