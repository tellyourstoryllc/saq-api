class FlagReason < ActiveRecord::Base
  include Peanut::Model

  validates :text, presence: true
  scope :active, -> { where(active: true) }
end
