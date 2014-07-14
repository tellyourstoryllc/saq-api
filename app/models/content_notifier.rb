class ContentNotifier
  MIN_CLIENT_VERSION = 206
  # Frequency of 0 means never send content pushes
  CONTENT_FREQUENCIES = [0, 5, 60]

  def send_notifications
    User.joins(:account).merge(Account.registered).includes(:ios_devices).find_in_batches do |group|
      content_push_infos = {}

      User.redis.pipelined do
        group.each do |user|
          content_push_infos[user.id] = User.redis.hmget(user.content_push_info.key, :frequency, :last_content_push_at)
        end
      end

      group.each do |user|
        info = content_push_infos[user.id].value

        content_frequency = info[0] || user.set_content_frequency
        content_frequency = content_frequency.to_i
        next if content_frequency == 0

        timestamp = info[1]
        last_content_push_at = timestamp.blank? ? nil : Time.zone.at(timestamp.to_i)

        #Rails.logger.debug "[User #{user.id}] content_frequency = #{content_frequency}; last_content_push_at = #{last_content_push_at}"

        user.mobile_notifier.notify_content_available if last_content_push_at.blank? || last_content_push_at <= content_frequency.minutes.ago
      end
    end
  end
end
