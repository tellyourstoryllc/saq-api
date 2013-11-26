# encoding: utf-8

class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick
  storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{id_hierarchy}/#{model.id}/#{model.uuid}"
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
end
