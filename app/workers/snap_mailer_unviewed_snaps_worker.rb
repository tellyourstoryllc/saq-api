class SnapMailerUnviewedSnapsWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(user_id, message_ids)
    perform_with_tracking(user_id, message_ids) do
      user = User.find(user_id)
      user.email_notifier.notify_unviewed_snaps!(message_ids)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
