class YouTubeStoryUploader
  attr_accessor :story


  def initialize(story = nil)
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
      user_video = FFMPEG::Movie.new(file.path)

      dir_path = Rails.configuration.app['youtube_video']['dir_path']
      body_path = File.join(dir_path, 'youtube_body.jpg')
      intro_path = File.join(dir_path, 'youtube_intro.mp4')
      outro_path = File.join(dir_path, 'youtube_outro.mp4')

      output_path = file.path + '_youtube.mp4'

      Rails.logger.debug "Creating YouTube video: #{video_url} #{output_path} ..."

      fade_in_duration = 1
      fade_out_duration = 1
      fade_out_frame_start = user_video.duration - fade_out_duration

      # Stitch together a YouTube video
      command = %(#{ffmpeg_bin} -loop 1 -i #{body_path} -i #{file.path} -i #{intro_path} -i #{outro_path} -filter_complex "amix=inputs=1 [mix]; [1:v] scale=500:-1 [scaled]; [scaled] fade=t=in:d=#{fade_in_duration} [fade_in]; [fade_in] fade=t=out:st=#{fade_out_frame_start}:d=#{fade_out_duration} [faded]; [0:v] [faded] overlay=x=main_w/2-overlay_w/2:y=210:shortest=1 [overlay]; [2:v] [2:a] [overlay] [mix] [3:v] [3:a] concat=n=3:v=1:a=1 [v] [a]" -map "[v]" -map "[a]" #{output_path})

      Rails.logger.debug "... with command #{command} ... "
      system(command)


      # Upload it to YouTube
      api_method = YOUTUBE_API.videos.insert

      title = "Story ##{Message.youtube_videos_count.incr} - #{Time.current.to_date.strftime("%B %-e, %Y")}"
      description = ''

      body = {snippet: {title: title, description: description}}
      #body[:status] = {privacyStatus: 'private'} unless Rails.env.production?
      body[:status] = {privacyStatus: 'private'} if Rails.env.development?

      media = Google::APIClient::UploadIO.new(output_path, 'video/*')
      params = {uploadType: 'resumable', part: body.keys.join(',')}

      result = YOUTUBE_CLIENT.execute!(api_method: api_method, body_object: body, media: media, parameters: params)
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

  def update(attrs)
    return if story.blank? || attrs.blank?

    if Settings.enabled?(:queue)
      YouTubeUpdateWorker.perform_async(story.id, attrs)
    else
      update!(attrs)
    end
  end

  def update!(attrs)
    return if story.blank? || attrs.blank?

    privacy = attrs['privacy']
    return unless %w(private public).include?(privacy)

    api_method = YOUTUBE_API.videos.update
    body = {id: story.youtube_id, status: {privacyStatus: privacy}}
    params = {part: body.keys.join(',')}

    api_args = {api_method: api_method, body_object: body, parameters: params}
    YOUTUBE_CLIENT.execute!(api_args)
  end

  def delete(youtube_id)
    return if youtube_id.blank?

    if Settings.enabled?(:queue)
      YouTubeDeleteWorker.perform_async(youtube_id)
    else
      delete!
    end
  end

  def delete!(youtube_id)
    return if youtube_id.blank?

    api_method = YOUTUBE_API.videos.delete
    params = {id: youtube_id}

    api_args = {api_method: api_method, parameters: params}
    YOUTUBE_CLIENT.execute!(api_args)
  end
end
