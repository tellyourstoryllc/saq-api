class AvatarVideo < ActiveRecord::Base
  before_validation :set_uuid, on: :create
  validates :user_id, :video, :uuid, presence: true
  belongs_to :user

  mount_uploader :video, AvatarVideoUploader


  private

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
