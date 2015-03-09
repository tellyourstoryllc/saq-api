class FlagReason < ActiveRecord::Base
  include Peanut::Model

  validates :text, presence: true
  scope :active, -> { where(active: true) }


  # "Count" this flag if we have no flag reasons,
  # or we do and this one should be moderated
  def moderate?
    !self.class.exists? || self[:moderate]
  end
end
