class YouTubeDeleteWorker < BaseWorker
  def self.category; :youtube end
  def self.metric; :delete end

  def perform(youtube_id)
    perform_with_tracking(youtube_id) do
      YouTubeStoryUploader.new.delete!(youtube_id)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
