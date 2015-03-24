class YouTube
  attr_accessor :video_url, :input_path


  def initialize(video_url)
    self.video_url = video_url
  end

  # TODO sidekiq job
  def create
    ffmpeg_bin = Rails.configuration.app['carrierwave']['ffmpeg_bin']
    FFMPEG.ffmpeg_binary = ffmpeg_bin

    # Download the source video, create the YouTube video, and upload it
    open(video_url) do |file|
      output_path = file.path + '_youtube.mp4'

      Rails.logger.debug "Creating YouTube video: #{video_url} #{output_path} ..."

      # Stitch together a YouTube video
      # TODO real command
      system("#{ffmpeg_bin} -i #{file.path} #{output_path}")


      # Upload it to YouTube

      # TODO delete output after uploading
    end
  end
end
