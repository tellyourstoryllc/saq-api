class AvatarImage < ActiveRecord::Base
  before_validation :set_uuid, on: :create
  validates :user_id, :image, :uuid, presence: true
  belongs_to :user

  mount_uploader :image, AvatarImageUploader


  private

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
