# encoding: utf-8

class EmoticonUploader < CarrierWave::Uploader::Base
  storage :fog

  configure do |config|
    config.remove_previously_stored_files_after_update = false
  end

  def cache_dir
    dir = Rails.configuration.app['carrierwave']['cache_dir']
    (dir && File.directory?(dir)) ? dir : super
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "static/emoticons/#{model.id}/#{model.sha1}"
  end
end
