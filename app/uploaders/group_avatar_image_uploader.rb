# encoding: utf-8

class GroupAvatarImageUploader < BaseUploader
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Create a 300x300 square thumbnail, cropping from center if necessary
  version :thumb do
    process resize_to_fill: [300, 300]
  end
end
