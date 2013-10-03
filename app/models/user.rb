class User < ActiveRecord::Base
  attr_accessor :guest

  validates :name, presence: true
  validates :email, format: /.+@.+/, unless: proc{ |u| u.guest }
  validates :password, presence: true, on: :create, unless: proc{ |u| u.guest }

  has_secure_password validations: false


  def object_type
    self.class.name.underscore
  end
end
