class Group < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  include Peanut::Conversation

  attr_accessor :anything_changed, :wallpaper_image_file, :wallpaper_creator_id, :delete_wallpaper

  before_validation :set_join_code, on: :create
  validates :creator_id, :name, :join_code, presence: true

  after_save :anything_changed?
  after_save :update_group_wallpaper_image, on: :update
  after_create :add_admin_and_member

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_one :group_wallpaper_image, -> { order('group_wallpaper_images.id DESC') }

  set :admin_ids
  set :member_ids
  sorted_set :message_ids


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

  def wallpaper_url
    @wallpaper_url ||= group_wallpaper_image.image.url if group_wallpaper_image.try(:active?)
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
    User.includes(:avatar_image).where(id: member_ids.members)
  end

  def fetched_member_ids
    member_ids.members.map(&:to_i)
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

  def update_group_wallpaper_image
    if wallpaper_image_file.present?
      create_group_wallpaper_image(creator_id: wallpaper_creator_id, image: wallpaper_image_file)
    elsif delete_wallpaper
      group_wallpaper_image.deactivate!
    end
  end

  def anything_changed?
    self.anything_changed = changed? || (wallpaper_image_file && wallpaper_creator_id) || delete_wallpaper
  end

  def add_admin_and_member
    return unless creator

    add_admin(creator)
    add_member(creator)
  end
end
