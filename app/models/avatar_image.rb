class AvatarImage < ActiveRecord::Base
  include Redis::Objects
  include Peanut::Flaggable
  include Peanut::SubmittedForYourApproval

  after_initialize :init_status
  before_validation :set_uuid, on: :create
  validates :user_id, :image, :uuid, presence: true
  belongs_to :user

  after_save :update_creator!
  after_create :check_censor_critical
  after_commit :check_censor_warning, on: :create
  after_destroy :update_creator!
  after_moderation_censor :add_censored_object

  mount_uploader :image, AvatarImageUploader


  protected

  def moderation_description
    "#{self.user.username} (#{Rails.env}): #{self.class.name} #{self.id}"
  end

  def moderation_url
    image.thumb.url
  end

  def moderation_increment_flags_censored?
    true
  end

  def update_creator!
    self.user.update_avatar_status!
  end


  private

  def init_status
    self.status = 'pending' if self.status.nil?
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end

  def check_censor_warning
    submit_to_moderator if user.censor_warning? && !user.censor_critical?
    true
  end

  def check_censor_critical
    auto_censor! if user.censor_critical?
    true
  end
end
