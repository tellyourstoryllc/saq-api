# encoding: utf-8

class MessageAttachmentUploader < BaseUploader
  include Peanut::AnimatedGif
  include CarrierWave::MimeTypes

  # Create a thumbnail with a max width of 300 and a max height of 300
  # Only resize if the width or height is larger than 300, and preserve aspect ratio
  version :thumb, {if: :image?} do
    process resize_to_limit: [300, 300]
  end
end
