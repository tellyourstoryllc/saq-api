# encoding: utf-8

class AvatarImageUploader < BaseUploader
  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    #Rails.configuration.app['assets']['url'] + ActionController::Base.helpers.asset_path("defaults/" + [version_name, "#{model.class.to_s.underscore}.png"].compact.join('_'))
    asset_host + ActionController::Base.helpers.asset_path("/defaults/" + [version_name, "#{model.class.to_s.underscore}.png"].compact.join('_'))
  end

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
