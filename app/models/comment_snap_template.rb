class CommentSnapTemplate < ActiveRecord::Base
  validates :name, :title_overlay, :body_overlay, presence: true
  scope :active, -> { where(active: true) }
end
