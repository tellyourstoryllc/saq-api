class SnapInviteAd < ActiveRecord::Base
  validates :name, :media_url, :text_overlay, presence: true
  scope :active, -> { where(active: true) }
end
