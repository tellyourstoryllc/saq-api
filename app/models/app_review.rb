class AppReview < ActiveRecord::Base
  validates :user_id, :rating, presence: true
  validates :rating, inclusion: (1..5)

  belongs_to :user
  belongs_to :device, polymorphic: true

  scope :latest, -> { order('id DESC') }
end
