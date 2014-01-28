class EmailDigestNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email_digest end

  def perform(user_id, job_token)
    perform_with_tracking(user_id, job_token) do
      user = User.find(user_id)

      # Only send the digest if the user has been unavailable the entire time since the last digest
      digests_sent = user.email_digests_sent.value
      if digests_sent > 0 && user.redis.get(EmailNotifier.job_token_key(user.id, digests_sent)) == job_token && user.away_idle_or_unavailable?
        user.email_notifier.send_notification(:all, nil, {skip_queue: true})
      end

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
