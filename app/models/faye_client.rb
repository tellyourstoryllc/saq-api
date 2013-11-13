class FayeClient
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :user_id, :status, :idled_at, :client_type, :created_at
  hash_key :attrs
  value :exists

  validates :id, :user_id, presence: true
  validates :idled_at, presence: true, if: proc{ |faye_client| faye_client.status == 'idle' && !%w(phone tablet).include?(faye_client.client_type) }


  def initialize(attributes = {})
    super
    to_int(:user_id, :idled_at, :created_at) if id.present?
  end

  def active?; status == 'active' end
  def idle?; status == 'idle' end

  def status=(new_status)
    @status = new_status if %w(active idle).include?(new_status)
  end

  def idle_duration=(duration)
    self.idled_at = duration.to_i.seconds.ago.to_i if duration.present?
  end

  def idle_duration
    Time.current.to_i - idled_at.to_i if idled_at.present?
  end

  def client_type=(type)
    @client_type = type if %w(web phone tablet).include?(type)
  end

  def save
    return unless valid?

    set_defaults
    write_attrs
    add_to_user
  end
  alias_method :save!, :save

  def user
    @user ||= User.find_by(id: user_id) if user_id
  end


  private

  # Only use for debugging purposes
  def destroy
    return if Rails.env.production?

    redis.multi do
      remove_from_user
      attrs.del
      exists.del
    end
  end

  def set_defaults
    self.created_at ||= Time.current.to_i
    self.client_type ||= 'web' # TODO: temporary until all clients have updated
  end

  def write_attrs
    self.attrs.bulk_set(id: id, user_id: user_id, status: status, idled_at: idled_at,
                        client_type: client_type, created_at: created_at)
  end

  def add_to_user
    user.connected_faye_client_ids[id] = Time.current.to_i if user
  end

  def remove_from_user
    user.connected_faye_client_ids.delete(id) if user
  end
end
