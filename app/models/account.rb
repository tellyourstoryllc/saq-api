class Account < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects

  attr_accessor :facebook_token, :one_to_one_wallpaper_image_file, :delete_wallpaper

  has_secure_password validations: false

  validates :email, format: /.+@.+/
  validates :email, uniqueness: true
  validates :password, presence: true, on: :create, if: proc{ |account| account.facebook_id.blank? && account.facebook_token.blank? }
  validate :valid_facebook_credentials?, on: :create

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

  def authenticate_facebook(facebook_token)
    self.facebook_token = facebook_token
    verify_facebook_token && self
  end


  private

  def valid_facebook_credentials?
    return if password.present?
    errors.add(:base, 'Invalid Facebook credentials') unless facebook_id.present? && facebook_token.present? && verify_facebook_token
  end

  def verify_facebook_token
    return false if facebook_token.blank?

    profile = Koala::Facebook::API.new(facebook_token).get_object('me')

    if profile['id'] == facebook_id
      FacebookUser.new(id: facebook_id).fetch_profile
      true
    else
      false
    end

  rescue Koala::Facebook::APIError
    false
  end

  def update_one_to_one_wallpaper_image
    if one_to_one_wallpaper_image_file.present?
      create_one_to_one_wallpaper_image(image: one_to_one_wallpaper_image_file)
    elsif delete_wallpaper
      one_to_one_wallpaper_image.deactivate!
    end
  end
end
