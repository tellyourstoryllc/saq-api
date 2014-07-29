class DripNotification < ActiveRecord::Base
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:rank) }
  scope :ios, -> { where(client: 'ios') }
  scope :android, -> { where(client: 'android') }

  DELAY = 24.hours


  def self.set_up_new_user(user, device)
    enabled = assign(user, device)
    send_initial_messages(user, device) if enabled
  end

  def self.assign(user, device)
    return false if !scope_for_client(device.client).exists?

    val = rand >= 0.5 ? 1 : 0
    user.redis.set(user.drip_notifications_enabled.key, val, {nx: true})
    val == 1
  end

  def self.scope_for_client(client)
    send(client).active.ordered
  end

  def self.send_initial_messages(user, device)
    return unless user.drip_notifications_enabled.value == '1'

    scope_for_client(device.client).pluck(:id).each_with_index do |id, i|
      # Delay each notification by the DELAY, starting one DELAY from now
      timespan = DELAY * (i + 1)
      DripNotificationWorker.perform_at(timespan.from_now, user.id, id)
    end

    user.drip_notifications_enabled = 2
  end
end
