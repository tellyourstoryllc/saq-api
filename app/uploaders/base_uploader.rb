# encoding: utf-8

class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :fog

  def cache_dir
    dir = Rails.configuration.app['carrierwave']['cache_dir']
    (dir && File.directory?(dir)) ? dir : super
  end

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if model.respond_to?(:sha) && model.sha.present?
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/sha/#{sha_hierarchy}"
    else
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{id_hierarchy}/#{model.id}/#{model.uuid}"
    end
  end

  def filename
    model.respond_to?(:sha) ? "#{model.sha}.#{file.extension}" : super
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

  # Limit the number of items in each subdirectory
  # to make manual browsing/lookups much faster
  def sha_hierarchy
    sha_string = model.sha.to_s
    dirs = [sha_string[0..1], sha_string[2..3], sha_string[4..5]]
    dirs.join('/')
  end

  def media_type(file)
    type = file.content_type
    MIME::Types[type].first.try(:media_type) || type.split('/').first
  end


  private

  def image?(file)
    media_type(file) == 'image'
  end

  def video?(file)
    media_type(file) == 'video'
  end
end
