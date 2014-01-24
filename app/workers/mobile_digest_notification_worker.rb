class MobileDigestNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :mobile_digest end

  def perform(user_id, message_id, job_token)
    perform_with_tracking(user_id, message_id, job_token) do
      user = User.find(user_id)
      message = Message.new(id: message_id)

      # Only send the digest if the user has been unavailable the entire time since the last digest
      digests_sent = user.mobile_digests_sent.value
      if digests_sent > 0 && user.redis.get(IosNotifier.job_token(user.id, digests_sent)) == job_token && user.away_idle_or_unavailable?
        user.ios_notifier.send_notification(message, :all)
      end

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
