class Group < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects

  before_validation :set_join_code, on: :create
  validates :creator_id, :name, :join_code, presence: true
  after_create :add_admin_and_member

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'

  set :admin_ids
  set :member_ids
  sorted_set :message_ids

  RECENT_MESSAGES_COUNT = 10


  def admin?(user)
    user && admin_ids.include?(user.id)
  end

  def member?(user)
    user && member_ids.include?(user.id)
  end

  def add_admin(user)
    self.admin_ids << user.id
  end

  def add_member(user)
    redis.multi do
      self.member_ids << user.id
      user.group_ids << id
    end
  end

  def members
    User.where(id: member_ids.members)
  end

  def recent_messages
    message_ids.range(-RECENT_MESSAGES_COUNT, -1).map{ |id| Message.new(id: id) }
  end


  private

  def set_join_code
    # Lowercase alpha chars only to make it easier to type on mobile
    # Exclude L to avoid any confusion
    chars = [*'a'..'k', *'m'..'z']
    self.join_code = Array.new(8){ chars.sample }.join
  end

  def add_admin_and_member
    return unless creator

    add_admin(creator)
    add_member(creator)
  end
end
