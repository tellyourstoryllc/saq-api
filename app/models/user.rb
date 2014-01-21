class User < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  attr_accessor :avatar_image_file, :avatar_image_url

  before_validation :set_id, :set_username, on: :create

  validates :name, :username, presence: true
  validates :username, uniqueness: true
  validates :status, inclusion: {in: %w[available away do_not_disturb]}

  validate :username_format?

  after_save :create_new_avatar_image, on: :update
  after_create :create_api_token

  has_one :account
  has_one :avatar_image, -> { order('avatar_images.id DESC') }
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'
  has_many :ios_devices
  has_many :emails

  set :group_ids
  sorted_set :group_join_times
  set :one_to_one_ids
  set :one_to_one_user_ids
  hash_key :api_tokens, global: true
  hash_key :user_ids_by_api_token, global: true
  sorted_set :connected_faye_client_ids
  value :idle_since
  value :last_client_disconnect_at
  value :last_mixpanel_checkin_at
  value :invited
  hash_key :metrics
  sorted_set :blocked_user_ids
  hash_key :group_last_seen_ranks
  hash_key :one_to_one_last_seen_ranks
  hash_key :last_group_pushes


  def first_name
    name.split(' ').first
  end

  def token
    @token ||= User.api_tokens[id] if id
  end

  def avatar_url
    @avatar_url ||= avatar_image.image.thumb.url if avatar_image
  end

  def groups
    Group.where(id: group_ids.members)
  end

  def one_to_ones
    OneToOne.pipelined_find(one_to_one_ids.members)
  end

  def conversations
    groups.includes(:group_avatar_image, :group_wallpaper_image) + one_to_ones
  end

  def clients
    FayeClient.pipelined_find(connected_faye_client_ids.members)
  end

  def most_recent_faye_client
    @most_recent_faye_client ||= begin
      client = nil
      ids = connected_faye_client_ids.revrange(0, -1)

      ids.each do |id|
        faye_client = FayeClient.new(id: id)

        if faye_client.active?
          client = faye_client
          break
        elsif faye_client.idle?
          client ||= faye_client
        end
      end

      client
    end
  end

  def computed_status
    client = most_recent_faye_client

    if client.nil?
      'unavailable'
    elsif client.idle?
      'idle'
    else
      self[:status]
    end
  end

  def computed_client_type
    most_recent_faye_client.try(:client_type)
  end

  def idle_duration
    since = idle_since.value
    Time.current.to_i - since.to_i if since.present?
  end

  def away_idle_or_unavailable?
    %w(away idle unavailable).include?(computed_status)
  end

  def contact_ids
    gids = group_ids.members
    group_member_keys = gids.map{ |group_id| "group:#{group_id}:member_ids" }
    one_to_one_user_keys = [one_to_one_user_ids.key]
    redis.sunion(group_member_keys + one_to_one_user_keys)
  end

  def self.contacts?(user1, user2)
    return false if user1.blank? || user2.blank?
    user1.id == user2.id || user1.contact_ids.include?(user2.id)
  end

  def contact?(user)
    return unless user && user.is_a?(User)

    @contacts_memoizer ||= {}
    is_contact = @contacts_memoizer[user.id]
    return is_contact unless is_contact.nil?

    @contacts_memoizer[user.id] = self.class.contacts?(self, user)
  end

  # Did the user join his first group (not including creating a group)
  # within 5 minutes of registering?
  def invited?
    invited_period = 5.minutes
    was_invited = invited.get

    if was_invited.nil?
      joined_group_ids = groups.where('creator_id != ?', id).pluck(:id)
      join_times = group_join_times.members(with_scores: true)
      joined_first_group_at = join_times.detect{ |group_id, time| joined_group_ids.include?(group_id) }.try(:last)

      invited_val = (joined_first_group_at && joined_first_group_at <= (created_at + invited_period).to_i) ? 1 : 0
      self.invited = invited_val if invited_val == 1 || created_at < invited_period.ago
      self.class.to_bool(invited_val)
    else
      self.class.to_bool(was_invited)
    end
  end

  def live_created_groups_count
    member_counts = redis.pipelined{ created_groups.map{ |g| g.member_ids.size } }
    member_counts.count{ |size| size > 1 }
  end

  def preferences
    UserPreferences.new(id: id)
  end

  def ios_notifier
    @ios_notifier ||= IosNotifier.new(self)
  end

  def email_notifier
    @email_notifier ||= EmailNotifier.new(self)
  end

  # Send notifications via all the user's channels, taking into account his preferences for each
  def send_notifications(message)
    return unless away_idle_or_unavailable?

    ios_notifier.notify(message)
    email_notifier.notify(message)
  end

  def block(user)
    return if blocked_user_ids.member?(user.id)

    blocked_user_ids[user.id] = Time.current.to_f

    one_to_one = OneToOne.new(sender_id: id, recipient_id: user.id)
    one_to_one.remove_from_lists if one_to_one.attrs.exists?
  end

  def unblock(user)
    blocked_user_ids.delete(user.id)

    one_to_one = OneToOne.new(sender_id: id, recipient_id: user.id)
    one_to_one.add_to_lists if one_to_one.attrs.exists?
  end

  def self.blocked?(user, other_user)
    replies = redis.pipelined do
      redis.zscore(user.blocked_user_ids.key, other_user.id)
      redis.zscore(other_user.blocked_user_ids.key, user.id)
    end

    !replies.all?(&:nil?)
  end

  def paginated_blocked_user_ids(options = {})
    max = 50
    options[:limit] ||= 10
    options[:limit] = 1 if options[:limit].to_i <= 0
    options[:limit] = max if options[:limit].to_i > max
    options[:limit] = options[:limit].to_i
    options[:offset] = options[:offset].to_i

    start = options[:offset]
    stop = options[:offset] + options[:limit] - 1

    blocked_user_ids.revrange(start, stop)
  end

  def paginated_blocked_users(options = {})
    user_ids = paginated_blocked_user_ids(options)

    if user_ids.present?
      field_order = user_ids.map{ |id| "'#{id}'" }.join(',')
      User.includes(:avatar_image).where(id: user_ids).order("FIELD(id, #{field_order})")
    else
      []
    end
  end



  private

  def set_id
    # Exclude L to avoid any confusion
    chars = [*'a'..'k', *'m'..'z', *0..9]

    loop do
      self.id = Array.new(8){ chars.sample }.join
      break unless User.where(id: id).exists?
    end
  end

  def set_username
    return if username.present?

    # Lowercase alpha chars only to make it easier to type on mobile
    # Exclude L to avoid any confusion
    chars = [*'a'..'k', *'m'..'z']

    loop do
      self.username = 'user_' + Array.new(6){ chars.sample }.join
      break unless User.where(username: username).exists?
    end
  end

  def username_format?
    return if username.blank?
    valid = username =~ /\Auser_[a-km-z]{6}\Z/ # system username
    valid ||= username =~ /[a-zA-Z]/ && username =~ /\A[a-zA-Z0-9]{2,16}\Z/
    errors.add(:username, "must be 2-16 characters, include at least one letter, and contain only letters and numbers") unless valid
  end

  def create_api_token
    loop do
      @token = SecureRandom.hex
      saved = redis.hsetnx(User.user_ids_by_api_token.key, @token, id)
      break if saved
    end

    User.api_tokens[id] = @token
  end

  def create_new_avatar_image
    if avatar_image_file.present?
      create_avatar_image(image: avatar_image_file)
    elsif avatar_image_url.present?
      create_avatar_image(remote_image_url: avatar_image_url)
    end
  end
end
