# encoding: utf-8

class MessageAttachmentUploader < BaseUploader
  include CarrierWave::MimeTypes

  def cache_dir
    '/mnt/rails/skymob-cache'
  end

  def media_type(file)
    MIME::Types[file.content_type].first.try(:media_type)
  end

  # Create a thumbnail with a max width of 300 and a max height of 300
  # Only resize if the width or height is larger than 300, and preserve aspect ratio
  version :thumb, {if: :image?} do
    process resize_to_limit: [300, 300]
  end

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
    input_duration = '-t 00:00:04.000' # Optional duration (hh:mm:ss.fff)
    output_resolution = '240x240'
    delay = 8 # milliseconds, whole number
    framerate = 12.5 # must equal 100 / DELAY

    system("#{ffmpeg_bin} -i #{input_path} -r #{framerate} #{input_offset} #{input_duration} -f image2pipe -vcodec rawvideo -pix_fmt rgb24 pipe:1 | #{convert_bin} -delay #{delay} -loop 0 -resize #{output_resolution} -layers Optimize -ordered-dither o8x8,24 -fuzz 4% -size #{size} -depth 8 rgb:- #{output_path} && mv #{output_path} #{input_path}")

    # Need to change this from video so it gets set properly on S3
    file.content_type = 'image/gif'
  end


  private

  def image?(file)
    media_type(file) == 'image'
  end

  def video?(file)
    media_type(file) == 'video'
  end
end
