class MessageMailerCensoredStoryWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(user_id, text)
    perform_with_tracking(user_id, text) do
      user = User.find(user_id)
      user.email_notifier.notify_censored_story!(text)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
