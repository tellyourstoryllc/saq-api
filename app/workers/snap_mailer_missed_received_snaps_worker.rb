class SnapMailerMissedReceivedSnapsWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(user_id)
    perform_with_tracking(user_id) do
      user = User.find(user_id)
      user.email_notifier.notify_missed_received_snaps!

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
