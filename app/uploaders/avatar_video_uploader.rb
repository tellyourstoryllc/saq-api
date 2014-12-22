# encoding: utf-8

class AvatarVideoUploader < BaseUploader
  include Peanut::AnimatedGif

#  version :thumbnails, {if: :flagged?} do
#    process :recreate_thumbnails
#  end
#
#  # Add a white list of extensions which are allowed to be uploaded.
#  def extension_white_list
#    %w(mp4)
#  end
#
#  def recreate_thumbnails
#    # If there were pre-existing thumbnails, destroy them.
#    model.thumbnails.destroy_all
#
#    # Get the length of the video.
#    movie = FFMPEG::Movie.new(current_path)
#    duration_in_seconds = movie.duration
#
#    # Create new thumbnails.
#    (0 .. duration_in_seconds.to_i).each do |i|
#      # Give it the video file.  It will convert it to an image based on the
#      # offset.
#      VideoThumbnail.create!(video: model, offset: i, image: file)
#    end
#  end
end
