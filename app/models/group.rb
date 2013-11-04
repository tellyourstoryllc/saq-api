class Group < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects

  attr_accessor :anything_changed

  before_validation :set_join_code, on: :create
  validates :creator_id, :name, :join_code, presence: true
  after_create :add_admin_and_member
  after_save :anything_changed?

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'

  set :admin_ids
  set :member_ids
  sorted_set :message_ids

  PAGE_SIZE = 20
  MAX_PAGE_SIZE = 200


  def admin?(user)
    user && admin_ids.include?(user.id)
  end

  def member?(user)
    user && member_ids.include?(user.id)
  end

  def add_admin(user)
    self.admin_ids << user.id
  end

  def remove_admin(user)
    admin_ids.delete(user.id)
  end

  def add_member(user)
    unless member_ids.member?(user.id)
      redis.multi do
        self.member_ids << user.id
        user.group_ids << id
      end
      true
    end
  end

  def leave!(user)
    if member_ids.member?(user.id)
      redis.multi do
        remove_admin(user)
        member_ids.delete(user.id)
        user.group_ids.delete(id)
      end
      true
    end
  end

  def members
    User.where(id: member_ids.members)
  end

  def paginate_messages(options = {})
    limit = [(options[:limit].presence || PAGE_SIZE).to_i, MAX_PAGE_SIZE].min
    return [] if limit == 0

    last_message_id = options[:last_message_id]

    ids = if last_message_id.present?
      message_ids.revrangebyscore("(#{last_message_id}", '-inf', {limit: limit}).reverse
    else
      message_ids.range(-limit, -1)
    end

    ids.map{ |id| Message.new(id: id) }
  end


  private

  def set_join_code
    # Lowercase alpha chars only to make it easier to type on mobile
    # Exclude L to avoid any confusion
    chars = [*'a'..'k', *'m'..'z']

    loop do
      self.join_code = Array.new(8){ chars.sample }.join
      break unless Group.where(join_code: join_code).exists?
    end
  end

  def add_admin_and_member
    return unless creator

    add_admin(creator)
    add_member(creator)
  end

  def anything_changed?
    self.anything_changed = changed?
  end
end
