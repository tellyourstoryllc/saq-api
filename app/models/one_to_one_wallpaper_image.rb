class OneToOneWallpaperImage < ActiveRecord::Base
  before_validation :set_uuid, on: :create
  validates :account_id, :image, :uuid, presence: true

  belongs_to :account

  mount_uploader :image, OneToOneWallpaperImageUploader


  def deactivate!
    update!(active: false)
  end


  private

  def set_uuid
    self.uuid = SecureRandom.uuid
  end
end
