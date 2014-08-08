class SnapInviteAd < ActiveRecord::Base
  validates :name, :media_url, :text_overlay, presence: true
  scope :active, -> { where(active: true) }
  scope :ios, -> { where(ios: true) }
  scope :android, -> { where(android: true) }
  scope :by_lang, -> (lang) { where(lang: lang) }
end
