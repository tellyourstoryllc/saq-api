class MessageAttachment < ActiveRecord::Base
  attr_writer :message
  before_validation :set_group_id, :set_one_to_one_id, :set_uuid, :update_attachment_attrs, on: :create
  validates :message_id, :attachment, :uuid, presence: true
  validates :sha, presence: true, on: :create

  mount_uploader :attachment, MessageAttachmentUploader


  def message
    @message ||= Message.new(id: message_id)
  end

  def preview_url
    if attachment.version_exists?(:thumb)
      attachment.thumb.url
    elsif attachment.version_exists?(:animated_gif)
      attachment.animated_gif.url
    end
  end

  def media_type_name
    return unless media_type.present?

    case media_type
    when 'image' then 'snap'
    when 'video' then 'video'
    when 'audio' then 'audio clip'
    else 'file'
    end
  end

  def friendly_media_type
    name = media_type_name
    return unless name.present?

    case name
    when 'snap' then 'a snap'
    when 'video' then 'a video'
    when 'audio clip' then 'an audio clip'
    else 'a file'
    end
  end

  def comment_friendly_media_type
    return unless media_type.present?

    case media_type
    when 'image' then 'a photo'
    when 'video' then 'a video'
    when 'audio' then 'an audio clip'
    else 'a file'
    end
  end


  private

  def set_group_id
    self.group_id = message.group_id
  end

  def set_one_to_one_id
    self.one_to_one_id = message.one_to_one_id
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end

  def update_attachment_attrs
    if attachment.present? && attachment_changed?
      self.media_type = attachment.media_type(attachment.file)
      self.content_type = attachment.file.content_type
      self.file_size = attachment.file.size
      self.sha = Digest::SHA1.file(attachment.file.path).hexdigest

      version = if attachment.version_exists?(:thumb)
                  attachment.thumb
                elsif attachment.version_exists?(:animated_gif)
                  attachment.animated_gif
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
