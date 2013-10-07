class User < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  attr_accessor :guest

  validates :name, presence: true
  validates :email, format: /.+@.+/, unless: proc{ |u| u.guest }
  validates :email, uniqueness: true
  validates :password, presence: true, on: :create, unless: proc{ |u| u.guest }

  has_secure_password validations: false

  after_create :create_api_token

  has_one :api_token
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'

  delegate :token, to: :api_token

  set :group_ids


  def groups
    Group.where(id: group_ids.members)
  end
end
