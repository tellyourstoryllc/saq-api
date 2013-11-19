class Account < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects

  attr_accessor :one_to_one_wallpaper_image_file, :delete_wallpaper

  validates :email, format: /.+@.+/
  validates :email, uniqueness: true

  has_secure_password validations: false
  after_save :update_one_to_one_wallpaper_image, on: :update

  belongs_to :user
  accepts_nested_attributes_for :user

  has_one :one_to_one_wallpaper_image, -> { order('one_to_one_wallpaper_images.id DESC') }


  def one_to_one_wallpaper_url
    @one_to_one_wallpaper_url ||= one_to_one_wallpaper_image.image.url if one_to_one_wallpaper_image.try(:active?)
  end

  def self.password_reset_token_key(token)
    "password_reset_token:#{token}"
  end

  def self.find_by_password_reset_token(token)
    return if token.blank?
    user_id = redis.get(password_reset_token_key(token))
    find_by(id: user_id) if user_id
  end

  def generate_password_reset_token
    token = SecureRandom.hex
    redis.setex(self.class.password_reset_token_key(token), 24.hours, id)
    token
  end


  private

  def update_one_to_one_wallpaper_image
    if one_to_one_wallpaper_image_file.present?
      create_one_to_one_wallpaper_image(image: one_to_one_wallpaper_image_file)
    elsif delete_wallpaper
      one_to_one_wallpaper_image.deactivate!
    end
  end
end
