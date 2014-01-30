class Phone < ActiveRecord::Base
  include Peanut::Model

  before_validation :normalize_number, :set_user

  validates :account, :user, presence: true
  validates :number, format: /\d+/
  validates :number, uniqueness: true

  belongs_to :account, inverse_of: :phones
  belongs_to :user


  def self.normalize(number)
    # Remove the optional +1 country code for US
    # TODO: Other country codes & formats
    Phony.normalize(number).sub(/^1?(\d{10})$/, '\1') if number
  rescue Phony::NormalizationError
  end

  def self.get(number)
    normalized_number = normalize(number)
    find_by(number: normalized_number) if normalized_number
  end


  private

  def normalize_number
    self.number = self.class.normalize(number)
  end

  def set_user
    self.user = account.user
  end
end
