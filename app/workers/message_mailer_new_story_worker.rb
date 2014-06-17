class MessageMailerNewStoryWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(story_id, recipient_id)
    perform_with_tracking(story_id, recipient_id) do
      story = Story.new(id: story_id)
      recipient = User.find(recipient_id)
      recipient.email_notifier.notify_story!(story)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
