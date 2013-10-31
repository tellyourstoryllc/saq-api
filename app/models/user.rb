class User < ActiveRecord::Base
  include Peanut::Model
  include Redis::Objects
  attr_accessor :guest

  validates :name, presence: true
  validates :email, format: /.+@.+/, unless: proc{ |u| u.guest }
  validates :email, uniqueness: true
  validates :status, inclusion: {in: %w[available away do_not_disturb]}
  validates :password, presence: true, on: :create, unless: proc{ |u| u.guest }

  has_secure_password validations: false

  after_create :create_api_token
  has_many :created_groups, class_name: 'Group', foreign_key: 'creator_id'

  set :group_ids
  hash_key :api_tokens, global: true
  hash_key :user_ids_by_api_token, global: true
  sorted_set :connected_faye_client_ids


  def first_name
    name.split(' ').first
  end

  def token
    @token ||= User.api_tokens[id] if id
  end

  def groups
    Group.where(id: group_ids.members)
  end

  def most_recent_faye_client
    @most_recent_faye_client ||= begin
      id = connected_faye_client_ids.last
      FayeClient.new(id: id) if id
    end
  end

  def computed_status
    @computed_status ||= begin
      client = nil
      ids = connected_faye_client_ids.revrange(0, -1)

      ids.each do |id|
        faye_client = FayeClient.new(id: id)

        if faye_client.active?
          client = faye_client
          break
        elsif faye_client.idle?
          client ||= faye_client
        end
      end

      if client.nil?
        'unavailable'
      elsif client.idle?
        'idle'
      else
        self[:status]
      end
    end
  end

  def idle_duration
    most_recent_faye_client.try(:idle_duration)
  end

  def idle_or_unavailable?
    %w(idle unavailable).include?(computed_status)
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
