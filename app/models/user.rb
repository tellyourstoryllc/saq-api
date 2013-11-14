class User < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  attr_accessor :guest, :avatar_image_file

  before_validation :set_username, on: :create

  validates :name, :username, presence: true
  validates :username, uniqueness: true
  validates :email, format: /.+@.+/, unless: proc{ |u| u.guest }
  validates :email, uniqueness: true
  validates :status, inclusion: {in: %w[available away do_not_disturb]}
  validates :password, presence: true, on: :create, unless: proc{ |u| u.guest }
  validate :username_format?

  has_secure_password validations: false

  after_save :create_new_avatar_image, on: :update
  after_create :create_api_token
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'
  has_one :avatar_image, -> { order('avatar_images.id DESC') }

  set :group_ids
  set :one_to_one_ids
  set :one_to_one_user_ids
  hash_key :api_tokens, global: true
  hash_key :user_ids_by_api_token, global: true
  sorted_set :connected_faye_client_ids


  def first_name
    name.split(' ').first
  end

  def token
    @token ||= User.api_tokens[id] if id
  end

  def avatar_url
    @avatar_url ||= (avatar_image || AvatarImage.new).image.thumb.url
  end

  def groups
    Group.where(id: group_ids.members)
  end

  def one_to_ones
    OneToOne.pipelined_find(one_to_one_ids.members)
  end

  def conversations
    groups + one_to_ones
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
    most_recent_faye_client.try(:idle_duration)
  end

  def away_idle_or_unavailable?
    %w(away idle unavailable).include?(computed_status)
  end

  def contact_ids
    gids = group_ids.members
    group_member_keys = gids.map{ |group_id| "group:#{group_id}:member_ids" }
    one_to_one_user_keys = [one_to_one_user_ids.key]
    redis.sunion(group_member_keys + one_to_one_user_keys).map!(&:to_i)
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

  def email_for_mention?
    # TODO: also check preferences
    away_idle_or_unavailable?
  end

  def email_for_one_to_one?
    # TODO: also check preferences
    away_idle_or_unavailable?
  end

  def preferences
    Preferences.new(id: id)
  end


  private

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
    create_avatar_image(image: avatar_image_file) unless avatar_image_file.blank?
  end
end
