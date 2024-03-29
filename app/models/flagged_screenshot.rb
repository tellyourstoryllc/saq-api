class FlaggedScreenshot < ActiveRecord::Base
  include Redis::Objects
  include Peanut::Flaggable
  include Peanut::SubmittedForYourApproval

  after_initialize :init_status
  before_validation :set_uuid, on: :create
  validates :user_id, :flagger_id, :image, :uuid, presence: true
  belongs_to :user

  after_save :update_creator!
  after_commit :submit_to_moderator, on: :create
  after_moderation_censor :add_censored_object

  mount_uploader :image, FlaggedScreenshotUploader


  def submit_to_moderator?
    pending?
  end


  protected

  def moderation_description
    "#{self.user.username} (#{Rails.env}): #{self.class.name} #{self.id}"
  end

  def moderation_url
    image.url
  end

  def moderation_increment_flags_censored?
    true
  end

  def update_creator!
    user.censor_profile! if censored?
  end

  # In addition to preventing multiple flags per screenshot,
  # also prevent multiple flags on the user itself
  def update_flag_metrics(flag_giver)
    super if user.flagger_ids.add(flag_giver.id)
  end


  private

  def init_status
    self.status = 'pending' if self.status.nil?
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end

  def add_censored_object
    user.add_censored_object(self)
  end
end
