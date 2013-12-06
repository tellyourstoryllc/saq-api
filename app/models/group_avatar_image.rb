class GroupAvatarImage < ActiveRecord::Base
  before_validation :set_uuid, on: :create
  validates :group_id, :creator_id, :image, :uuid, presence: true

  belongs_to :group
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'

  mount_uploader :image, GroupAvatarImageUploader


  def deactivate!
    update!(active: false)
  end


  private

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
