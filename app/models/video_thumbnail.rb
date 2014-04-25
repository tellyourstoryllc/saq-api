class VideoThumbnail < ActiveRecord::Base
  include Peanut::SubmittedForYourApproval

  after_initialize :init_status
  validates :video_id, :image, :offset, presence: true
  belongs_to :video, class_name: 'AvatarVideo'

  after_save :update_creator!
  after_destroy :update_creator!

  mount_uploader :image, VideoThumbnailUploader


  protected

  def moderation_description
    "#{self.user.username} (#{Rails.env}): #{self.class.name} #{self.id}"
  end

  def moderation_url
    image.snapshot.url
  end

  def update_creator!
    self.video.update_creator!
  end


  private

  def init_status
    self.status = 'pending' if self.status.nil?
  end
end
