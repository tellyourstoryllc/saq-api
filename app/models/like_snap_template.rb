class LikeSnapTemplate < ActiveRecord::Base
  validates :name, :text_overlay, presence: true
  scope :active, -> { where(active: true) }
end
