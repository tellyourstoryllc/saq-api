class AvatarImage < ActiveRecord::Base
  include Peanut::SubmittedForYourApproval

  after_initialize :init_status
  before_validation :set_uuid, on: :create
  validates :user_id, :image, :uuid, presence: true
  belongs_to :user

  after_save :update_creator!
  after_destroy :update_creator!

  mount_uploader :image, AvatarImageUploader


  def flag(actor, flag_reason)
    submit_to_moderator if flag_reason.moderate? && pending?

    actor.misc.incr('flags_given')
    user.misc.incr('flags_received')
  end


  protected

  def moderation_description
    "#{self.user.username} (#{Rails.env}): #{self.class.name} #{self.id}"
  end

  def moderation_url
    image.thumb.url
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

end
