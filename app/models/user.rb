class User < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  attr_accessor :avatar_image_file, :avatar_image_url, :avatar_video_file, :invite_type

  before_validation :set_id, on: :create
  before_validation :fix_username

  validates :username, presence: true
  validates :username, uniqueness: true
  validates :status, inclusion: {in: %w[available away do_not_disturb]}

  validate :valid_username?, :username_format?

  after_save :update_sorting_name
  after_save :create_new_avatar_image, :create_new_avatar_video, on: :update
  after_create :create_api_token

  has_one :account
  has_one :avatar_image, -> { order('avatar_images.id DESC') }
  has_one :avatar_video, -> { order('avatar_videos.id DESC') }
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'
  has_many :ios_devices
  has_many :android_devices
  has_many :emails
  has_many :phones
  has_many :received_invites, class_name: 'Invite', foreign_key: 'recipient_id'

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
  value :last_mixpanel_message_at
  value :last_mixpanel_message_to_bot_at
  value :invited
  value :sorting_name # Used for sorting contacts lists
  hash_key :metrics
  sorted_set :blocked_user_ids
  hash_key :group_last_seen_ranks
  hash_key :one_to_one_last_seen_ranks
  hash_key :phone_verification_tokens, global: true
  hash_key :user_ids_by_phone_verification_token, global: true

  value :last_mobile_digest_notification_at
  counter :mobile_digests_sent
  sorted_set :mobile_digest_group_ids
  value :last_email_digest_notification_at
  counter :email_digests_sent
  sorted_set :email_digest_group_ids

  set :contact_ids
  set :reciprocal_contact_ids
  sorted_set :replaced_user_ids
  value :replaced_by_user_id

  set :unread_convo_ids
  set :phone_contacts
  set :matching_phone_contact_user_ids
  set :snapchat_friend_ids
  set :snapchat_friend_phone_numbers
  value :set_initial_snapchat_friend_ids_in_app
  set :initial_snapchat_friend_ids_in_app

  value :assigned_snap_invite_ad_id
  value :last_invite_at
  value :clicked_invite_link
  value :notified_friends
  value :daily_missed_sent_snaps_email
  value :daily_missed_received_snaps_email
  sorted_set :unviewed_message_ids
  set :unviewed_message_user_ids, global: true
  value :snap_invites_allowed
  value :sms_invites_allowed

  delegate :registered, :registered?, to: :account

  COHORT_METRICS_TIME_ZONE = 'America/New_York'


  def first_name
    name.present? ? name.split(' ').first : username
  end

  # Don't use name for anything...
  def name
    username
  end

  def token
    @token ||= User.api_tokens[id] if id
  end

  def fetch_phone_verification_token
    @phone_verification_token ||= User.phone_verification_tokens[id] || create_phone_verification_token if id
  end

  def avatar_url
    @avatar_url ||= avatar_image.image.thumb.url if avatar_image
  end

  def avatar_video_url
    @avatar_video_url ||= avatar_video.video.url if avatar_video
  end

  def avatar_video_preview_url
    @avatar_video_preview_url ||= avatar_video.preview_url if avatar_video
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

  def most_recent_faye_client(reload = false)
    if reload
      @most_recent_faye_client = get_most_recent_faye_client
    else
      @most_recent_faye_client ||= get_most_recent_faye_client
    end
  end

  def computed_status(reload = false)
    client = most_recent_faye_client(reload)

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

  def self.away_idle_or_unavailable?(status)
    %w(away idle unavailable).include?(status)
  end

  def away_idle_or_unavailable?
    self.class.away_idle_or_unavailable?(computed_status)
  end

  def dynamic_contact_ids
    gids = group_ids.members
    group_member_keys = gids.map{ |group_id| "group:#{group_id}:member_ids" }
    one_to_one_user_keys = [one_to_one_user_ids.key]

    redis.sunion([contact_ids.key] + group_member_keys + one_to_one_user_keys)
  end

  def contact?(user)
    return unless user && user.is_a?(User)

    @contacts_memoizer ||= {}
    is_contact = @contacts_memoizer[user.id]
    return is_contact unless is_contact.nil?

    @contacts_memoizer[user.id] = contact_ids.include?(user.id)
  end

  def dynamic_contact?(user)
    return unless user && user.is_a?(User)

    @dynamic_contacts_memoizer ||= {}
    is_contact = @dynamic_contacts_memoizer[user.id]
    return is_contact unless is_contact.nil?

    @dynamic_contacts_memoizer[user.id] = dynamic_contact_ids.include?(user.id)
  end

  # Did another user send an email or SMS invite to this person before he registered?
  # Or did the user join his first group (not including creating a group)
  # within 5 minutes of registering?
  def invited?
    was_invited = invited.get

    if was_invited.nil?
      if received_invites.exists?
        self.invited = 1
        true
      else
        invited_period = 5.minutes
        joined_group_ids = groups.where('creator_id != ?', id).pluck(:id)
        join_times = group_join_times.members(with_scores: true)
        joined_first_group_at = join_times.detect{ |group_id, time| joined_group_ids.include?(group_id) }.try(:last)

        invited_val = (joined_first_group_at && joined_first_group_at <= (created_at + invited_period).to_i) ? 1 : 0
        self.invited = invited_val if invited_val == 1 || created_at < invited_period.ago # Keep checking for the first 5 mins
        self.class.to_bool(invited_val)
      end
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

  def mobile_notifier
    @mobile_notifier ||= MobileNotifier.new(self)
  end

  def email_notifier
    @email_notifier ||= EmailNotifier.new(self)
  end

  # Send notifications via all the user's channels, taking into account his preferences for each
  def send_notifications(message)
    return unless away_idle_or_unavailable? && !bot? && !message.received

    if !mobile_notifier.notify(message)
      email_notifier.notify(message)  # only send email notification if no mobile notification was sent.
    end
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
    return if user.nil? || other_user.nil?

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
      User.includes(:avatar_image, :avatar_video).where(id: user_ids).order("FIELD(id, #{field_order})")
    else
      []
    end
  end

  # Reset digests if the user just went from not available to available
  def reset_digests_if_needed(old_status, new_status)
    if self.class.away_idle_or_unavailable?(old_status) && !self.class.away_idle_or_unavailable?(new_status)
      reset_digest_cycle
    end
  end

  # Reset all digest data when the user becomes available
  def reset_digest_cycle
    keys = [last_mobile_digest_notification_at, mobile_digests_sent,
      last_email_digest_notification_at, email_digests_sent].map!(&:key)

    # Delete only the few most recent job keys (the rest should have already expired)
    # So we're not deleting potentially hundreds of keys for lost users
    mobile_sent = mobile_digests_sent.value
    ([mobile_sent - 3, 1].max).upto(mobile_sent + 1){ |i| keys << MobileNotifier.job_token_key(id, mobile_sent) }

    email_sent = email_digests_sent.value
    ([email_sent - 3, 1].max).upto(email_sent + 1){ |i| keys << EmailNotifier.job_token_key(id, email_sent) }

    keys += mobile_digest_data_keys
    keys += email_digest_data_keys

    redis.del(keys)
  end

  # Reset badge count if the user just went from not available to available
  def reset_badge_count_if_needed(old_status, new_status)
    if self.class.away_idle_or_unavailable?(old_status) && !self.class.away_idle_or_unavailable?(new_status)
      unread_convo_ids.del
    end
  end

  def delete_mobile_digest_data
    redis.del(mobile_digest_data_keys)
  end

  def delete_email_digest_data
    redis.del(email_digest_data_keys)
  end

  def mobile_digest_data_keys
    [mobile_digest_group_ids.key] + mobile_digest_group_ids.members.map do |group_id|
      MobileNotifier.group_chatting_member_ids_key(id, group_id)
    end
  end

  def email_digest_data_keys
    [email_digest_group_ids.key] + email_digest_group_ids.members.map do |group_id|
      EmailNotifier.group_chatting_member_ids_key(id, group_id)
    end
  end

  def paginated_contact_ids(options = {})
    max = 50
    options[:limit] ||= 10
    options[:limit] = 1 if options[:limit].to_i <= 0
    options[:limit] = max if options[:limit].to_i > max

    contact_ids.sort(by: 'user:*:sorting_name', limit: [options[:offset], options[:limit]], order: 'ALPHA')
  end

  def paginated_contacts(options = {})
    user_ids = paginated_contact_ids(options)

    if user_ids.present?
      field_order = user_ids.map{ |id| "'#{id}'" }.join(',')
      User.includes(:avatar_image, :avatar_video, :emails, :phones).where(id: user_ids).order("FIELD(id, #{field_order})")
    else
      []
    end
  end

  def deactivate!
    update!(deactivated: true)
  end

  def snap_invite_ad
    return @snap_invite_ad if defined?(@snap_invite_ad)

    snap_invite_ad_id = assigned_snap_invite_ad_id.value
    unless snap_invite_ad_id && (@snap_invite_ad = SnapInviteAd.active.find_by(id: snap_invite_ad_id))
      @snap_invite_ad = SnapInviteAd.active.order('RAND()').first
      self.assigned_snap_invite_ad_id = snap_invite_ad.id
    end

    @snap_invite_ad
  end

  def self.cohort_metrics_key(date)
    "user::metrics:registered_on:#{date}" if date.present?
  end

  def cohort_metrics_key
    self.class.cohort_metrics_key(account.registered_at.in_time_zone(COHORT_METRICS_TIME_ZONE).to_date) if account.registered_at.present?
  end

  def self.user_ids_who_friended_me_key(user_id)
    "user:#{user_id}:user_ids_who_friended_me"
  end

  def user_ids_who_friended_me_key
    self.class.user_ids_who_friended_me_key(id)
  end

  def user_ids_who_friended_me
    redis.smembers(user_ids_who_friended_me_key)
  end

  def add_to_user_ids_who_friended_me(friend_ids)
    redis.pipelined do
      friend_ids.each do |friend_id|
        redis.sadd(self.class.user_ids_who_friended_me_key(friend_id), id)
      end
    end
  end

  def notify_friends
    return if notified_friends.get
    self.notified_friends = '1'

    # TODO: maybe move to Sidekiq
    User.where(id: user_ids_who_friended_me).find_each do |friend|
      friend.mobile_notifier.notify_friend_joined(self)
    end
  end

  def self.daily_user_ids_in_eastern_key(date = Time.find_zone('America/New_York').today)
    "user::metrics:daily_user_ids_in_eastern:#{date}"
  end

  def active_on?(date)
    return @active_on[date] if @active_on && !@active_on[date].nil?

    @active_on ||= {}
    key = self.class.daily_user_ids_in_eastern_key(date)
    @active_on[date] = redis.sismember(key, id)
  end

  def snapchat_friend_ids_in_app
    Account.where(user_id: snapchat_friend_ids.members).registered.pluck(:user_id)
  end

  def bot?
    Robot.bot?(self)
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

  def fix_username
    if username.blank?
      # Lowercase alpha chars only to make it easier to type on mobile
      # Exclude L to avoid any confusion
      chars = [*'a'..'k', *'m'..'z']
      prefix = "_#{invite_type || 'user'}_"

      loop do
        self.username = prefix + Array.new(6){ chars.sample }.join
        break unless User.where(username: username).exists?
      end
    else
      self.username = username.gsub(/[+ ]/, '_')

      base_username = username
      i = 0

      loop do
        break unless User.where(username: username).where('id != ?', id).exists? || username == Robot.username
        i += 1
        self.username = "#{base_username}_#{i}"
      end
    end
  end

  def valid_username?
    errors.add(:username, "must be valid.") if username == 'teamsnapchat'
  end

  def username_format?
    return if username.blank?
    valid = username =~ /[a-zA-Z]/ && username =~ /\A[a-zA-Z0-9_\-.]{2,16}\Z/
    errors.add(:username, "must be 2-16 characters, include at least one letter, and contain only letters, numbers, _, -, and .") unless valid
  end

  def create_api_token
    loop do
      @token = SecureRandom.hex
      saved = redis.hsetnx(User.user_ids_by_api_token.key, @token, id)
      break if saved
    end

    User.api_tokens[id] = @token
  end

  def create_phone_verification_token
    chars = [*'a'..'z', *0..9]

    loop do
      @phone_verification_token = Array.new(8){ chars.sample }.join
      saved = redis.hsetnx(User.user_ids_by_phone_verification_token.key, @phone_verification_token, id)
      break if saved
    end

    User.phone_verification_tokens[id] = @phone_verification_token
  end

  def update_sorting_name
    self.sorting_name = username if username_changed?
  end

  def create_new_avatar_image
    if avatar_image_file.present?
      create_avatar_image(image: avatar_image_file)
    elsif avatar_image_url.present?
      create_avatar_image(remote_image_url: avatar_image_url)
    end
  end

  def create_new_avatar_video
    create_avatar_video(video: avatar_video_file) if avatar_video_file.present?
  end

  def get_most_recent_faye_client
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
