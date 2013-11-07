class MessageImage < ActiveRecord::Base
  attr_writer :message
  before_validation :set_group_id, :set_one_to_one_id, :set_uuid, on: :create
  validates :message_id, :image, :uuid, presence: true
  validate :group_id_or_one_to_one_id?

  mount_uploader :image, MessageImageUploader


  def message
    @message ||= Message.new(id: message_id)
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
end
