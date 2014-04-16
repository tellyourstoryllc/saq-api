class Phone < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects

  before_validation :normalize_number, :set_hashed_number, :set_user_and_account,
    :set_verification_code

  validates :account, :user, :hashed_number, presence: true
  validates :number, format: /\d+/
  validates :number, :hashed_number, uniqueness: true

  after_save :delete_verification_token

  belongs_to :account, inverse_of: :phones
  belongs_to :user

  value :notified_friends
  scope :verified, -> { where(verified: true) }


  def self.normalize(number)
    # Remove any non-digit chars and the optional +1 country code for US
    # TODO: Other country codes & formats
    number.gsub(/\D/, '').gsub(/^\+?1(\d{10})$/, '\1') if number
  end

  def self.get(number)
    normalized_number = normalize(number)
    find_by(number: normalized_number) if normalized_number
  end

  def verify_by_code!(current_user, code, options = {})
    verify!(current_user, options) if verification_code.present? && verification_code == code
  end

  def verify!(current_user, options = {})
    return if current_user.nil?

    self.user = current_user
    old_user_id = user_id_was if user_id_was && user_id_changed?

    self.verified = true
    save!

    merge_users(old_user_id)
    notify_friends if options[:notify_friends]
  end

  def pretty
    case number.size
    when 10 then '1-' + number[0..2] + '-' + number[3..5] + '-' + number[6..9]
    else number
    end
  end

  def self.phone_contact_of_user_ids_key(hashed_phone_number)
    "hashed_phone_number:#{hashed_phone_number}:phone_contact_of_user_ids"
  end

  def phone_contact_of_user_ids_key
    self.class.phone_contact_of_user_ids_key(hashed_number)
  end

  def phone_contact_of_user_ids
    redis.smembers(phone_contact_of_user_ids_key)
  end

  def self.add_user_to_phone_contacts(user, hashed_phone_numbers)
    redis.pipelined do
      hashed_phone_numbers.each do |hashed_phone_number|
        redis.sadd(phone_contact_of_user_ids_key(hashed_phone_number), user.id)
      end
    end
  end

  def merge_users(old_user_id)
    return if old_user_id.nil?

    old_user = User.find_by(id: old_user_id)
    UserMerger.merge(old_user, user)
  end

  def notify_friends
    return if notified_friends.get
    self.notified_friends = '1'

    # TODO: maybe move to Sidekiq
    User.where(id: phone_contact_of_user_ids).find_each do |friend|
      friend.mobile_notifier.notify_friend_joined(user)
    end
  end


  private

  def normalize_number
    self.number = self.class.normalize(number)
  end

  def set_hashed_number
    self.hashed_number = Digest::SHA2.new(256).hexdigest(number) if number
  end

  def set_user_and_account
    if account && user.nil?
      self.user = account.user
    elsif user && account.nil?
      self.account = user.account
    elsif user_id_was && user_id_changed?
      self.account_id = user.account.id
    elsif account_id_was && account_id_changed?
      self.user_id = account.user_id
    end
  end

  def set_verification_code
    return if verification_code.present?

    chars = [*0..9]
    self.verification_code = Array.new(4){ chars.sample }.join
  end

  def delete_verification_token
    return unless !verified_was && verified && user

    token = User.phone_verification_tokens[user.id]

    User.redis.multi do
      User.phone_verification_tokens.delete(user.id)
      User.user_ids_by_phone_verification_token.delete(token) if token
    end
  end
end
