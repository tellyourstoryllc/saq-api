class MessageImage < ActiveRecord::Base
  attr_writer :message
  before_validation :set_group_id, :set_uuid, on: :create
  validates :group_id, :message_id, :image, :uuid, presence: true

  mount_uploader :image, MessageImageUploader


  def message
    @message ||= Message.new(id: message_id)
  end


  private

  def set_group_id
    self.group_id = message.group_id
  end

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
