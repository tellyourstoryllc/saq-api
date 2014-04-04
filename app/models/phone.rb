class Phone < ActiveRecord::Base
  include Peanut::Model

  before_validation :normalize_number, :set_hashed_number, :set_user,
    :set_account, :set_verification_code

  validates :account, :user, :hashed_number, presence: true
  validates :number, format: /\d+/
  validates :number, :hashed_number, uniqueness: true

  after_save :delete_verification_token

  belongs_to :account, inverse_of: :phones
  belongs_to :user

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

  def verify_by_code!(code)
    verify! if verification_code.present? && verification_code == code
  end

  def verify!
    self.verified = true
    save!
  end

  def pretty
    case number.size
    when 10 then '1-' + number[0..2] + '-' + number[3..5] + '-' + number[6..9]
    else number
    end
  end


  private

  def normalize_number
    self.number = self.class.normalize(number)
  end

  def set_hashed_number
    self.hashed_number = Digest::SHA2.new(256).hexdigest(number) if number
  end

  def set_user
    self.user ||= account.try(:user)
  end

  def set_account
    self.account ||= user.try(:account)
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
      User.user_ids_by_phone_verification_token.delete(token)
    end
  end
end
