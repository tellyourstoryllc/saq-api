class BotMessage < ActiveRecord::Base
  validates :user_id, :message_id, presence: true
  belongs_to :user

  scope :latest, -> { order('id DESC') }
end
