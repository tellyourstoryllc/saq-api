class ApiToken < ActiveRecord::Base
  before_validation :set_token
  validates :user_id, :token, presence: true
  belongs_to :user


  private

  def set_token
    self.token = SecureRandom.hex
  end
end
