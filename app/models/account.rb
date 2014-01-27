class Account < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects

  attr_accessor :facebook_token, :one_to_one_wallpaper_image_file, :delete_wallpaper

  has_secure_password validations: false

  before_validation :set_time_zone, on: :create
  validate :valid_facebook_credentials?, on: :create
  validate :time_zone_set?
  after_save :update_one_to_one_wallpaper_image, on: :update

  belongs_to :user
  has_many :emails, inverse_of: :account
  has_one :one_to_one_wallpaper_image, -> { order('one_to_one_wallpaper_images.id DESC') }

  accepts_nested_attributes_for :user, :emails


  def time_zone=(tz_name)
    self[:time_zone_offset] = ActiveSupport::TimeZone.new(tz_name).try(:utc_offset)
    self[:time_zone] = tz_name
  end

  def one_to_one_wallpaper_url
    @one_to_one_wallpaper_url ||= one_to_one_wallpaper_image.image.url if one_to_one_wallpaper_image.try(:active?)
  end

  def self.password_reset_token_key(token)
    "password_reset_token:#{token}"
  end

  def self.find_by_password_reset_token(token)
    return if token.blank?
    account_id = redis.get(password_reset_token_key(token))
    find_by(id: account_id) if account_id
  end

  def generate_password_reset_token
    token = "#{id}-#{SecureRandom.hex}"
    redis.setex(self.class.password_reset_token_key(token), 24.hours, id)
    token
  end

  def authenticate_facebook(facebook_token)
    self.facebook_token = facebook_token
    verify_facebook_token && self
  end

  def send_welcome_email
    if Settings.enabled?(:queue)
      WelcomeEmailWorker.perform_async(id)
    else
      send_welcome_email!
    end
  end

  def send_welcome_email!
    AccountMailer.welcome(self).deliver!
  end

  def no_login_credentials?
    password_digest.blank? && facebook_id.blank?
  end

  def send_missing_password_email
    return unless no_login_credentials?

    if Settings.enabled?(:queue)
      MissingPasswordWorker.perform_in(10.seconds, id)
    else
      send_missing_password_email!
    end
  end

  def send_missing_password_email!
    AccountMailer.missing_password(self, generate_password_reset_token).deliver!
  end


  private

  def set_time_zone
    self.time_zone ||= 'America/New_York'
  end

  def time_zone_set?
    errors.add(:base, "Time zone is required.") if time_zone.blank? || time_zone_offset.blank?
  end

  def valid_facebook_credentials?
    errors.add(:base, 'Invalid Facebook credentials') if (facebook_id.present? && facebook_token.blank?) ||
      (facebook_id.blank? && facebook_token.present?) ||
      (facebook_id.present? && facebook_token.present? && !verify_facebook_token)
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
