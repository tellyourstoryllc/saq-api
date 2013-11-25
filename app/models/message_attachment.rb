class MessageAttachment < ActiveRecord::Base
  attr_writer :message
  before_validation :set_group_id, :set_one_to_one_id, :set_uuid, :update_attachment_attrs, on: :create
  validates :message_id, :attachment, :uuid, presence: true
  validate :group_id_or_one_to_one_id?

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


  private

  def group_id_or_one_to_one_id?
    attrs = [group_id, one_to_one_id]
    errors.add(:base, "Must specify exactly one of group_id or one_to_one_id.") if attrs.all?(&:blank?) || attrs.all?(&:present?)
  end

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
      self.media_type = attachment.media_type(attachment.file) || attachment.file.content_type.split('/').first
      self.content_type = attachment.file.content_type
      self.file_size = attachment.file.size
    end
  end
end
