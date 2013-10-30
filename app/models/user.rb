class User < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  attr_accessor :guest, :include_contact_ids

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
  sorted_set :connected_faye_client_ids


  def token
    @token ||= User.api_tokens[id] if id
  end

  def groups
    Group.where(id: group_ids.members)
  end

  def contact_ids
    gids = group_ids.members
    group_member_keys = gids.map{ |group_id| "group:#{group_id}:member_ids" }
    redis.sunion(group_member_keys).map!(&:to_i)
  end

  def most_recent_faye_client
    @most_recent_faye_client ||= begin
      id = connected_faye_client_ids.last
      FayeClient.new(id: id) if id
    end
  end

  def computed_status
    client = most_recent_faye_client

    if client.nil?
      'unavailable'
    elsif client.idle?
      'idle'
    else
      self[:status]
    end
  end

  def idle_duration
    most_recent_faye_client.try(:idle_duration)
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
