class Group < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  include Peanut::Conversation

  attr_accessor :wallpaper_image_file, :wallpaper_image_url,
    :wallpaper_creator_id, :delete_wallpaper, :avatar_image_file, :avatar_image_url,
    :avatar_creator_id, :delete_avatar

  before_validation :set_id, :set_join_code, on: :create
  validates :creator_id, :name, :join_code, presence: true

  after_save :update_group_avatar_image, :update_group_wallpaper_image, on: :update
  after_create :add_admin_and_member

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_one :group_avatar_image, -> { order('group_avatar_images.id DESC') }
  has_one :group_wallpaper_image, -> { order('group_wallpaper_images.id DESC') }

  set :admin_ids
  set :member_ids
  sorted_set :banned_user_ids
  value :last_mixpanel_activity_at
  value :last_mixpanel_message_at
  value :last_mixpanel_fetched_messages_at


  def admin?(user)
    user && admin_ids.include?(user.id)
  end

  def member?(user)
    user && member_ids.include?(user.id)
  end

  def add_admin(user)
    self.admin_ids << user.id unless banned?(user)
  end

  def remove_admin(user)
    admin_ids.delete(user.id)
  end

  def admins
    User.where(id: admin_ids.members)
  end

  def avatar_url
    @avatar_url ||= group_avatar_image.image.thumb.url if group_avatar_image.try(:active?)
  end

  def wallpaper_url
    @wallpaper_url ||= group_wallpaper_image.image.url if group_wallpaper_image.try(:active?)
  end

  def add_member(user)
    if member_ids.member?(user.id)
      :already_member
    elsif banned?(user)
      false
    else
      redis.multi do
        self.member_ids << user.id
        user.group_ids << id
        user.group_join_times[id] = Time.current.to_i
      end

      publish_updated_group(user)
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

      publish_updated_group(user)
      true
    end
  end

  def members(options = {includes: [:avatar_image]})
    scope = User
    scope = scope.includes(options[:includes]) if options[:includes].present?
    scope.where(id: member_ids.members)
  end

  def fetched_member_ids
    member_ids.members
  end

  def can_view_bans?(current_user)
    admin?(current_user)
  end

  def can_ban?(current_user, user)
    admin?(current_user) && !admin?(user)
  end

  def can_unban?(current_user, user)
    admin?(current_user)
  end

  def banned?(user)
    banned_user_ids.member?(user.id)
  end

  def ban(user)
    return if banned_user_ids.member?(user.id)

    banned_user_ids[user.id] = Time.current.to_f
    leave!(user)
  end

  def unban(user)
    banned_user_ids.delete(user.id)
  end

  def paginated_banned_user_ids(options = {})
    max = 50
    options[:limit] ||= 10
    options[:limit] = 1 if options[:limit].to_i <= 0
    options[:limit] = max if options[:limit].to_i > max
    options[:limit] = options[:limit].to_i
    options[:offset] = options[:offset].to_i

    start = options[:offset]
    stop = options[:offset] + options[:limit] - 1

    banned_user_ids.revrange(start, stop)
  end

  def paginated_banned_users(options = {})
    user_ids = paginated_banned_user_ids(options)

    if user_ids.present?
      field_order = user_ids.map{ |id| "'#{id}'" }.join(',')
      User.includes(:avatar_image).where(id: user_ids).order("FIELD(id, #{field_order})")
    else
      []
    end
  end

  def active_members
    @active_members ||= members.reject(&:away_idle_or_unavailable?)
  end


  private

  def set_id
    # Exclude L to avoid any confusion
    chars = [*'a'..'k', *'m'..'z']

    loop do
      self.id = Array.new(6){ chars.sample }.join
      break unless Group.where(id: id).exists?
    end
  end

  def set_join_code
    self.join_code = id

    # Lowercase alpha chars only to make it easier to type on mobile
    # Exclude L to avoid any confusion
    #chars = [*'a'..'k', *'m'..'z']

    #loop do
    #  self.join_code = Array.new(5){ chars.sample }.join
    #  break unless Group.where(join_code: join_code).exists?
    #end
  end

  def update_group_avatar_image
    if avatar_image_file.present?
      create_group_avatar_image(creator_id: avatar_creator_id, image: avatar_image_file)
    elsif avatar_image_url.present?
      create_group_avatar_image(creator_id: avatar_creator_id, remote_image_url: avatar_image_url)
    elsif delete_avatar
      group_avatar_image.deactivate!
    end
  end

  def update_group_wallpaper_image
    if wallpaper_image_file.present?
      create_group_wallpaper_image(creator_id: wallpaper_creator_id, image: wallpaper_image_file)
    elsif wallpaper_image_url.present?
      create_group_wallpaper_image(creator_id: wallpaper_creator_id, remote_image_url: wallpaper_image_url)
    elsif delete_wallpaper
      group_wallpaper_image.deactivate!
    end
  end

  def add_admin_and_member
    return unless creator

    add_admin(creator)
    add_member(creator)
  end

  def publish_updated_group(user)
    publisher = FayePublisher.new(user.token)
    publisher.publish_to_group(self, PublishGroupSerializer.new(self).as_json)
    publisher.publish_group_to_user(user, GroupSerializer.new(self).as_json)
  end
end
