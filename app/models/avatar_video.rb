class AvatarVideo < ActiveRecord::Base
  before_validation :set_uuid, :update_video_attrs, on: :create
  validates :user_id, :video, :uuid, presence: true
  belongs_to :user
  has_many :thumbnails, {inverse_of: :video, class_name: 'VideoThumbnail'}, -> { order('video_thumbnails.offset') }

  mount_uploader :video, AvatarVideoUploader


  def preview_url
    video.animated_gif.url if video.version_exists?(:animated_gif)
  end

  def update_creator!
    self.user.update_avatar_video_status!
  end


  private

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
end
