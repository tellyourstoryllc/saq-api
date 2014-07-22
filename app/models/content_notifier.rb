class ContentNotifier
  MIN_CLIENT_VERSION = 206

  # Frequency of 0 means never send content pushes
  # Frequency is in minutes and unanswered_count is cumulative
  # e.g. For the 5 frequency, send every 5 minutes 3 times,
  # then every 12 hours 6 times, then every 7 days forever
  # Each device increases levels like this until a checkin occurs
  CONTENT_FREQUENCIES = {
    0 => nil,
    5 => [
      {frequency: 5, unanswered_count: 3},   # 5 minutes
      {frequency: 720, unanswered_count: 9}, # 12 hours
      {frequency: 10080}                     # 7 days
    ],
    60 => [
      {frequency: 60, unanswered_count: 3},  # 60 minutes
      {frequency: 720, unanswered_count: 9}, # 12 hours
      {frequency: 10080}                     # 7 days
    ]
  }


  def send_notifications
    User.joins(:account).merge(Account.registered).includes(:ios_devices).find_in_batches do |group|
      user_content_push_infos = {}
      device_content_push_infos = {}

      User.redis.pipelined do
        group.each do |user|
          user_content_push_infos[user.id] = User.redis.hmget(user.content_push_info.key, :frequency)

          user.ios_devices.each do |device|
            device_content_push_infos[device.id] = User.redis.hmget(device.content_push_info.key, :current_frequency, :last_content_push_at, :unanswered_count)
          end
        end
      end

      group.each do |user|
        info = user_content_push_infos[user.id].value

        user_frequency = (info[0] || user.set_content_frequency).to_i
        next if user_frequency == 0

        user.ios_devices.each do |device|
          device_info = device_content_push_infos[device.id].value

          device_frequency = device_info[0].to_i
          timestamp = device_info[1]
          unanswered_count = device_info[2].to_i

          content_frequency = device.current_content_frequency(user_frequency, device_frequency, unanswered_count).to_i
          next if content_frequency == 0

          last_content_push_at = timestamp.blank? ? nil : Time.zone.at(timestamp.to_i)

          #Rails.logger.debug "[User #{user.id}] content_frequency = #{content_frequency}; last_content_push_at = #{last_content_push_at}"

          user.mobile_notifier.notify_content_available(device) if last_content_push_at.blank? || last_content_push_at <= content_frequency.minutes.ago
        end
      end
    end
  end
end
