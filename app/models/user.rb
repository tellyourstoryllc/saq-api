class User < ActiveRecord::Base
  include PeanutModel
  attr_accessor :guest

  validates :name, presence: true
  validates :email, format: /.+@.+/, unless: proc{ |u| u.guest }
  validates :password, presence: true, on: :create, unless: proc{ |u| u.guest }

  has_secure_password validations: false

  after_create :create_api_token

  has_one :api_token
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'

  delegate :token, to: :api_token
end
