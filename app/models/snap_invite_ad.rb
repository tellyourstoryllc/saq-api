class SnapInviteAd < ActiveRecord::Base
  translates :name, :media_url, :text_overlay

  validates :name, :media_url, :text_overlay, presence: true
  scope :active, -> { where(active: true) }
  scope :ios, -> { where(ios: true) }
  scope :android, -> { where(android: true) }
end
