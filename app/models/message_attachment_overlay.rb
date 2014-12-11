class MessageAttachmentOverlay < ActiveRecord::Base
  attr_writer :message
  before_validation :set_one_to_one_id, :set_uuid, :update_attachment_attrs, on: :create
  validates :message_id, :overlay, :uuid, presence: true

  mount_uploader :overlay, MessageAttachmentOverlayUploader


  def message
    @message ||= Message.new(id: message_id)
  end


  private

  def set_one_to_one_id
    self.one_to_one_id = message.one_to_one_id
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end

  def update_attachment_attrs
    if overlay.present? && overlay_changed?
      self.file_size = overlay.file.size
    end
  end
end
