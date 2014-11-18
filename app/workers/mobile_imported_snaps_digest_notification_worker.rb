class MobileImportedSnapsDigestNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :mobile_snaps_digest end

  def perform(user_id)
    perform_with_tracking(user_id) do
      user = User.find(user_id)

      # Only send the digest if the user has been unavailable the entire time since the last digest
      # Check for '1' instead of presence, since we don't want it to send if it's 'cancelled'
      if user.misc['pending_imported_digest'] == '1' && user.away_idle_or_unavailable?
        user.mobile_notifier.send_snap_digest_notifications
      end

      user.reset_imported_snaps_digest

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
