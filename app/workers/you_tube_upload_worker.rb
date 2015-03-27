class YouTubeUploadWorker < BaseWorker
  def self.category; :youtube end
  def self.metric; :upload end

  def perform(story_id)
    perform_with_tracking(story_id) do
      story = Story.new(id: story_id)
      YouTubeStoryUploader.new(story).create!
    end
  end

  statsd_measure :perform, metric_prefix
end
