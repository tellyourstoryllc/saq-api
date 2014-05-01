class SnapInviteAd < ActiveRecord::Base
  validates :name, :image_url, :text_overlay, presence: true
end
