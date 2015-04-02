class YouTubeStoryUploader
  attr_accessor :story


  def initialize(story)
    self.story = story
  end

  def create
    if Settings.enabled?(:queue)
      YouTubeUploadWorker.perform_async(story.id)
    else
      create!
    end
  end

  def create!
    ffmpeg_bin = Rails.configuration.app['carrierwave']['ffmpeg_bin']
    FFMPEG.ffmpeg_binary = ffmpeg_bin

    # Download the source video, create the YouTube video, and upload it
    output_path = nil
    video_url = story.attachment_url

    open(video_url) do |file|
      output_path = file.path + '_youtube.mp4'

      Rails.logger.debug "Creating YouTube video: #{video_url} #{output_path} ..."

      # Stitch together a YouTube video
      # TODO real command
      command = "#{ffmpeg_bin} -i #{file.path} #{output_path}"

      Rails.logger.debug "... with command #{command} ... "
      system(command)


      # Upload it to YouTube
      api_method = YOUTUBE_API.videos.insert

      title = Rails.configuration.app['app_name'].dup
      description = ''

      body = {snippet: {title: title, description: description}}
      #body[:status] = {privacyStatus: 'private'} unless Rails.env.production?
      body[:status] = {privacyStatus: 'private'} if Rails.env.development?

      media = Google::APIClient::UploadIO.new(output_path, 'video/*')
      params = {uploadType: 'resumable', part: body.keys.join(',')}

      result = YOUTUBE_CLIENT.execute(api_method: api_method, body_object: body, media: media, parameters: params)
      youtube_id = JSON.load(result.body)['id']

      if youtube_id.present?
        story.youtube_id = youtube_id
        story.attrs[:youtube_id] = youtube_id
      else
        Rails.logger.warn("Failed to created YouTube video for story #{story.id}")
      end

      story.delete_youtube_lock_key
    end

  ensure
    File.delete(output_path) if File.exists?(output_path)
  end
end
