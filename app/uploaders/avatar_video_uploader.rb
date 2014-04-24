# encoding: utf-8

class AvatarVideoUploader < BaseUploader
  include Peanut::AnimatedGif

  # Add a white list of extensions which are allowed to be uploaded.
  def extension_white_list
    %w(mp4)
  end
end
