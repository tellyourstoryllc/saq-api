class FlaggedScreenshot < ActiveRecord::Base
  include Redis::Objects
  include Peanut::Flaggable
  include Peanut::SubmittedForYourApproval

  after_initialize :init_status
  before_validation :set_uuid, on: :create
  validates :user_id, :flagger_id, :image, :uuid, presence: true
  belongs_to :user

  after_save :update_creator!
  after_commit :submit_to_moderator

  mount_uploader :image, FlaggedScreenshotUploader


  def flag(flag_giver)
    submit_to_moderator if submit_to_moderator?
    update_flag_metrics(flag_giver)
  end


  protected

  def moderation_description
    "#{self.user.username} (#{Rails.env}): #{self.class.name} #{self.id}"
  end

  def moderation_url
    image.url
  end

  def update_creator!
    #self.user.update_censored_profile!
  end


  private

  def init_status
    self.status = 'pending' if self.status.nil?
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
