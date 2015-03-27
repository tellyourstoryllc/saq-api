class YouTubeUploadWorker < BaseWorker
  def self.category; :youtube end
  def self.metric; :upload end

  def perform(video_url, public_username)
    perform_with_tracking(video_url, public_username) do
      YouTube.new(video_url, public_username).create!
    end
  end

  statsd_measure :perform, metric_prefix
end
