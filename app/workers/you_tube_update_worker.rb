class YouTubeUpdateWorker < BaseWorker
  def self.category; :youtube end
  def self.metric; :update end

  def perform(story_id, attrs)
    perform_with_tracking(story_id, attrs) do
      story = Story.new(id: story_id)
      YouTubeStoryUploader.new(story).update!(attrs)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
