class AvatarVideo < ActiveRecord::Base
  include Redis::Objects
  include Peanut::Flaggable
  include Peanut::SubmittedForYourApproval

  after_initialize :init_status
  before_validation :set_uuid, :update_video_attrs, on: :create
  validates :user_id, :video, :uuid, presence: true
  belongs_to :user

  after_save :update_creator!
  after_create :check_censor_critical
  after_commit :check_censor_warning, on: :create
  after_destroy :update_creator!
  after_moderation_censor :add_censored_object

  mount_uploader :video, AvatarVideoUploader


  def preview_url
    if video.version_exists?(:animated_gif)
      video.animated_gif.url
    elsif video.version_exists?(:screenshot)
      video.screenshot.url
    end
  end


  private

  def init_status
    self.status = 'pending' if self.status.nil?
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end

  def update_video_attrs
    if video.present? && video_changed?
      self.media_type = video.media_type(video.file)
      self.content_type = video.file.content_type
      self.file_size = video.file.size

      version = if video.version_exists?(:thumb)
                  video.thumb
                elsif video.version_exists?(:animated_gif)
                  video.animated_gif
                end
      if version
        img = MiniMagick::Image.open(version.file.file)
        if img
          self.preview_width = img[:width]
          self.preview_height = img[:height]
        end
      end
    end
  end

  def update_creator!
    self.user.update_avatar_video_status!
  end

  def moderation_description
    "#{self.user.username} (#{Rails.env}): #{self.class.name} #{self.id}"
  end

  def moderation_url
    video.url
  end

  def moderation_type
    :video
  end

  def moderation_increment_flags_censored?
    true
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
