class YouTube
  attr_accessor :video_url, :public_username, :input_path


  def initialize(video_url, public_username)
    self.video_url = video_url
    self.public_username = public_username
  end

  # TODO sidekiq job
  def create
    ffmpeg_bin = Rails.configuration.app['carrierwave']['ffmpeg_bin']
    FFMPEG.ffmpeg_binary = ffmpeg_bin

    # Download the source video, create the YouTube video, and upload it
    output_path = nil
    open(video_url) do |file|
      output_path = file.path + '_youtube.mp4'

      Rails.logger.debug "Creating YouTube video: #{video_url} #{output_path} ..."

      # Stitch together a YouTube video
      # TODO real command
      command = "#{ffmpeg_bin} -i #{file.path} #{output_path}"

      Rails.logger.debug "... with command #{command} ... "
      system(command)


      # Upload it to YouTube
      title = Rails.configuration.app['app_name']
      title += ": #{public_username}" if public_username
      description = 'desc'

      body = {
        snippet: {title: title, description: description},
        status: {privacyStatus: 'private'}
      }

      api_method = YOUTUBE_API.videos.insert
      media = Google::APIClient::UploadIO.new(output_path, 'video/*')
      params = {uploadType: 'resumable', part: body.keys.join(',')}

      result = YOUTUBE_CLIENT.execute(api_method: api_method, body_object: body, media: media, parameters: params)
      return JSON.load(result.body)['id']
    end

  ensure
    File.delete(output_path) if File.exists?(output_path)
  end
end
