class AppReview < ActiveRecord::Base
  validates :user_id, :rating, presence: true
  validates :rating, inclusion: (1..5)

  scope :latest, -> { order('id DESC') }
end
