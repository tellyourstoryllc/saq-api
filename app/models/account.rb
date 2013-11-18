class Account < ActiveRecord::Base
  include Peanut::Model

  attr_accessor :one_to_one_wallpaper_image_file

  validates :email, format: /.+@.+/
  validates :email, uniqueness: true

  has_secure_password validations: false
  after_save :create_new_one_to_one_wallpaper_image, on: :update

  belongs_to :user
  accepts_nested_attributes_for :user


  has_one :one_to_one_wallpaper_image, -> { order('one_to_one_wallpaper_images.id DESC') }


  def one_to_one_wallpaper_url
    @one_to_one_wallpaper_url ||= one_to_one_wallpaper_image.image.url if one_to_one_wallpaper_image
  end


  private

  def create_new_one_to_one_wallpaper_image
    create_one_to_one_wallpaper_image(image: one_to_one_wallpaper_image_file) unless one_to_one_wallpaper_image_file.blank?
  end
end
