class Email < ActiveRecord::Base
  include Peanut::Model

  before_validation :normalize_email, :set_user

  validates :account, :user, presence: true
  validates :email, format: /.+@.+/
  validates :email, uniqueness: true

  before_destroy :not_last_email?

  belongs_to :account, inverse_of: :emails
  belongs_to :user


  def self.normalize(email)
    email.downcase.strip if email
  end

  def self.get(email)
    find_by(email: normalize(email))
  end


  private

  def normalize_email
    self.email = self.class.normalize(email)
  end

  def set_user
    self.user = account.user
  end

  def not_last_email?
    if account.emails.size <= 1
      errors.add(:base, "Sorry, you need at least one email address.")
      false
    end
  end
end
