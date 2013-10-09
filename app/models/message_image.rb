class MessageImage < ActiveRecord::Base
  attr_writer :message
  before_validation :set_group_id, on: :create
  validates :group_id, :message_id, :image, presence: true

  mount_uploader :image, MessageImageUploader


  def message
    @message ||= Message.new(id: message_id)
  end


  private

  def set_group_id
    self.group_id = message.group_id
  end
end
