class WidgetNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :widget end

  def perform(user_id)
    perform_with_tracking(user_id) do
      user = User.find(user_id)
      user.send_widget_notifications

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
