module Peanut::VideoThumbnail
  extend ActiveSupport::Concern

  included do
    version :screenshot, {if: :video?} do
      process :create_screenshot

      # Hack to change the version's file extension
      def full_filename(for_file)
        super.sub(/\..+$/, '.jpg')
      end
    end

    # Create a screenshot with a max width and height of 300, preserving aspect ratio
    def create_screenshot
      Rails.logger.debug "Creating video screenshot #{current_path} #{file.inspect} ..."

      cache_stored_file! if !cached?

      ffmpeg_bin = Rails.configuration.app['carrierwave']['ffmpeg_bin']
      input_path = current_path
      output_path = input_path.sub(/\..+$/, '.jpg')

      FFMPEG.ffmpeg_binary = ffmpeg_bin
      FFMPEG.logger = Rails.logger

      movie = FFMPEG::Movie.new(input_path)

      dimension = movie.width > movie.height ? :width : :height
      movie.screenshot(output_path, {resolution: '300,300'}, {preserve_aspect_ratio: dimension})

      FileUtils.mv(output_path, input_path)

      # Need to change this from video so it gets set properly on S3
      file.content_type = 'image/jpeg'

      model.duration = movie.duration.round
    end
  end
end
