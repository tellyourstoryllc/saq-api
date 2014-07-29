class DripNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :drip end

  def perform(user_id, id)
    perform_with_tracking(user_id, id) do
      user = User.find(user_id)
      notification = DripNotification.find(id)
      user.send_drip_notifications(notification)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
