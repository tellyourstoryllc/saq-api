class SnapMailerNewSnapWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(user_id, sender_id)
    perform_with_tracking(user_id, sender_id) do
      user = User.find(user_id)
      sender = User.find(sender_id)
      user.email_notifier.notify_new_snap!(sender) if user.away_idle_or_unavailable?

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
