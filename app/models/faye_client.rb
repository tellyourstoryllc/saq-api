class FayeClient
  include Peanut::RedisModel
  include Redis::Objects

  attr_accessor :id, :user_id, :status, :client_type, :created_at, :idle_duration
  hash_key :attrs
  value :exists

  validates :id, :user_id, :client_type, presence: true
  validates :idle_duration, presence: true, if: proc{ |faye_client| faye_client.status == 'idle' && !%w(phone tablet).include?(faye_client.client_type) }
  validate :exists?


  def initialize(attributes = {})
    super
    to_int(:created_at) if id.present?
  end

  def active?; status == 'active' end
  def idle?; status == 'idle' end

  def status=(new_status)
    @status = new_status if %w(active idle).include?(new_status)
  end

  def client_type=(type)
    @client_type = type if %w(web phone tablet).include?(type)
  end

  def save
    return unless valid?

    set_defaults
    write_attrs
    update_user

    true
  end
  alias_method :save!, :save

  def user
    @user ||= User.find_by(id: user_id) if user_id
  end

  def destroy
    redis.multi do
      remove_from_user
      attrs.del
      exists.del
    end
  end


  private

  # Protect against race conditions that lead to stale clients
  def exists?
    unless exists.exists?
      destroy
      errors.add(:base, "Doesn't exist in Faye, so self-destructing.")
    end
  end

  def set_defaults
    self.created_at ||= Time.current.to_i
  end

  def write_attrs
    self.attrs.bulk_set(id: id, user_id: user_id, status: status, client_type: client_type, created_at: created_at)
  end

  def update_user
    user.connected_faye_client_ids[id] = Time.current.to_i if user

    if status == 'active'
      user.idle_since.del
    elsif status == 'idle' && idle_duration.present? && user.clients.none?(&:active?)
      # Update the user's idle time to either the passed-in time or the user's
      # last active time, but only if it's more recent than the exising idle time
      old_time = user.idle_since.to_i
      new_time = idle_duration.to_i.seconds.ago.to_i
      last_active_time = user.last_client_disconnect_at.to_i
      new_idle_since = [new_time, last_active_time].max

      user.idle_since = new_idle_since if new_idle_since > old_time
    end
  end

  def remove_from_user
    user.connected_faye_client_ids.delete(id) if user
  end
end
