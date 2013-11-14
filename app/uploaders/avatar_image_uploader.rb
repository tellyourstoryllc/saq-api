# encoding: utf-8

class AvatarImageUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  # storage :file
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{id_hierarchy}/#{model.id}/#{model.uuid}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    #Rails.configuration.app['assets']['url'] + ActionController::Base.helpers.asset_path("defaults/" + [version_name, "#{model.class.to_s.underscore}.png"].compact.join('_'))
    #"#{Rails.configuration.app['assets']['url']}/images/defaults/" + [version_name, "avatar_image.png"].compact.join('_')
    'https://s3.amazonaws.com/' + Rails.configuration.app['aws']['bucket_name'] + ActionController::Base.helpers.asset_path("/defaults/" + [version_name, "#{model.class.to_s.underscore}.png"].compact.join('_'))
  end

  # Process files as they are uploaded:
  # process :scale => [200, 300]

  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :thumb do
    process resize_to_fit: [300, 300]
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Limit the number of items in each subdirectory
  # to make manual browsing/lookups much faster
  def id_hierarchy
    id_string = model.id.to_s
    dirs = []

    while !id_string.empty?
      dirs << id_string.slice!(0..1).ljust(2, '0')
    end

    dirs.join('/')
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end