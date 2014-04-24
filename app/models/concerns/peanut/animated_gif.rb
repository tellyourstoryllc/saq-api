module Peanut::AnimatedGif
  extend ActiveSupport::Concern

  included do
    version :animated_gif, {if: :video?} do
      process :create_animated_gif

      # Hack to change the version's file extension
      def full_filename(for_file)
        super.sub(/\..+$/, '.gif')
      end
    end

    def create_animated_gif
      Rails.logger.debug "Animating video #{current_path} #{file.inspect} ..."

      ffmpeg_bin = Rails.configuration.app['carrierwave']['ffmpeg_bin']
      convert_bin = Rails.configuration.app['carrierwave']['convert_bin']

      cache_stored_file! if !cached?

      input_path = current_path
      output_path = input_path.sub(/\..+$/, '.gif')

      FFMPEG.ffmpeg_binary = ffmpeg_bin
      movie = FFMPEG::Movie.new(input_path)

      # The movie.resolution parser is incorrect for some videos
      size = movie.video_stream.match(/, (\d{2,4}x\d{2,4})/)[1]

      input_offset = '-ss 00:00:00.000' # Optional starting offset (hh:mm:ss.fff)
      input_duration = '-t 00:00:03.000' # Optional duration (hh:mm:ss.fff)
      output_resolution = '240x240'
      delay = 16 # milliseconds, whole number
      framerate = 6.25 # must equal 100 / DELAY

      system("#{ffmpeg_bin} -i #{input_path} -r #{framerate} #{input_offset} #{input_duration} -f image2pipe -vcodec rawvideo -pix_fmt rgb24 pipe:1 | #{convert_bin} -delay #{delay} -loop 0 -resize #{output_resolution} -layers Optimize -ordered-dither o8x8,24 -fuzz 4% -size #{size} -depth 8 rgb:- #{output_path} && mv #{output_path} #{input_path}")

      # Need to change this from video so it gets set properly on S3
      file.content_type = 'image/gif'
    end
  end
end
