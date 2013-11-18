class Account < ActiveRecord::Base
  include Peanut::Model

  validates :email, format: /.+@.+/
  validates :email, uniqueness: true

  has_secure_password validations: false

  belongs_to :user
  accepts_nested_attributes_for :user


  def one_to_one_wallpaper_url
    # TODO
  end
end
