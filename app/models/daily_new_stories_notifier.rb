class DailyNewStoriesNotifier
  # Notify each user who hasn't logged in within a day
  # about the new stories from the past day
  def self.send_daily_notifications
    metrics_key = "user::sent_recent_stories_notifications_metrics:#{Time.zone.today}"
    yesterday = 24.hours.ago
    stories_count = Message.recent_story_ids.range_size(yesterday.to_i, 'inf')

    User.redis.hset(metrics_key, :stories_count, stories_count)

    return if stories_count == 0

    User.includes(:ios_devices, :android_devices).where('users.last_checkin_at < ?', yesterday).find_each do |user|
      next unless user.mobile_notifier.pushes_enabled?

      user.mobile_notifier.notify_recent_stories(stories_count)

      User.redis.hincrby(metrics_key, :recipients_count, 1)
    end
  end
end
