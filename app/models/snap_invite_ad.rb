class SnapInviteAd < ActiveRecord::Base
  validates :name, :image_url, :text_overlay, presence: true
  scope :active, -> { where(active: true) }
end
