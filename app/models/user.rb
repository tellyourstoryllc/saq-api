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
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'

  set :group_ids
  hash_key :api_tokens, global: true
  hash_key :user_ids_by_api_token, global: true


  def token
    @token ||= User.api_tokens[id] if id
  end

  def groups
    Group.where(id: group_ids.members)
  end


  private

  def create_api_token
    loop do
      @token = SecureRandom.hex
      saved = redis.hsetnx(User.user_ids_by_api_token.key, @token, id)
      break if saved
    end

    User.api_tokens[id] = @token
  end
end
