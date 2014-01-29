class Phone < ActiveRecord::Base
  include Peanut::Model

  before_validation :normalize_number, :set_user

  validates :account, :user, presence: true
  validates :number, format: /\d+/
  validates :number, uniqueness: true

  belongs_to :account, inverse_of: :phones
  belongs_to :user


  def self.normalize(number)
    Phony.normalize(number) if number
  end

  def self.get(number)
    find_by(number: normalize(number))
  end


  private

  def normalize_number
    self.number = self.class.normalize(number)
  end

  def set_user
    self.user = account.user
  end
end
