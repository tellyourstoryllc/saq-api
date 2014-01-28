class MessageMailerWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email_content_or_digest end

  def perform(notification_subtype, user_id, message_id, data)
    perform_with_tracking(notification_subtype, user_id, message_id, data) do
      user = User.find(user_id)
      message = Message.new(id: message_id) if notification_subtype.to_sym == :content
      user.email_notifier.send_digest_notification!(notification_subtype, data, message)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
