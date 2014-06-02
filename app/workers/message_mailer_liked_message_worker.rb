class MessageMailerLikedMessageWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(message_id, actor_id)
    perform_with_tracking(message_id, actor_id) do
      message = Message.new(id: message_id)
      actor = User.find(actor_id)
      message.user.email_notifier.notify_like!(message, actor)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
