class Group < ActiveRecord::Base
  include PeanutModel
  include Redis::Objects

  before_validation :set_join_code
  validates :creator_id, :name, :join_code, presence: true
  after_create :add_admin_and_member

  set :admin_ids
  set :member_ids


  private

  def set_join_code
    chars = [*'a'..'z', *'A'..'Z']
    self.join_code = Array.new(8){ chars.sample }.join
  end

  def add_admin_and_member
    return unless creator_id

    self.admin_ids << creator_id
    self.member_ids << creator_id
  end
end
