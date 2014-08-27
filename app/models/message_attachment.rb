class MessageAttachment < ActiveRecord::Base
  attr_writer :message
  before_validation :set_group_id, :set_one_to_one_id, :set_uuid, :update_attachment_attrs, on: :create
  validates :message_id, :attachment, :uuid, presence: true
  validates :sha, presence: true, on: :create

  mount_uploader :attachment, MessageAttachmentUploader
  skip_callback :save, :after, :store_attachment!, if: :skip_storage?
  after_commit :delete_temp_files


  def skip_storage?
    @skip_storage ||= self.class.where(sha: sha).where('message_attachments.id != ?', id).exists?
  end

  def delete_temp_files
    if attachment.delete_tmp_file_after_storage && !attachment.move_to_store && attachment.file.path.include?('/tmp/')
      temp_files = [attachment.file.path] + attachment.versions.map{ |k,v| v.file.try(:path) }.compact
      temp_files.each do |path|
        File.delete(path) if File.exist?(path)
      end
    end
  end

  def sha
    if self[:sha].present?
      self[:sha]
    else
      self.sha = Digest::SHA1.file(attachment.file.path).hexdigest
    end
  end

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
