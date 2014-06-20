class MessageMailerStoryCommentWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(comment_id, recipient_id)
    perform_with_tracking(comment_id, recipient_id) do
      comment = Comment.new(id: comment_id)
      recipient = User.find(recipient_id)
      recipient.email_notifier.notify_story_comment!(comment)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
