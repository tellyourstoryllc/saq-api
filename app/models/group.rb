class Group < ActiveRecord::Base
  include PeanutModel

  before_validation :set_join_code
  validates :creator_id, :name, :join_code, presence: true


  private

  def set_join_code
    chars = [*'a'..'z', *'A'..'Z']
    self.join_code = Array.new(8){ chars.sample }.join
  end
end
