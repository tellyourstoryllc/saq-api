class FlagReason < ActiveRecord::Base
  validates :text, presence: true
  scope :active, -> { where(active: true) }
end
