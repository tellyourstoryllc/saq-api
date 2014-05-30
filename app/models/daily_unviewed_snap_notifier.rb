class DailyUnviewedSnapNotifier
  STALENESS_TIME = 12.hours

  # Send an email to each user who has at least 1 unviewed
  # snap that's at least X hours old
  def self.send_daily_emails
    metrics_key = "user::sent_unviewed_message_email_metrics:#{Time.zone.today}"

    user_ids = User.unviewed_message_user_ids.members
    User.where(id: user_ids).find_each do |user|
      # Only send an email if the user has pushes enabled
      if !user.mobile_notifier.pushes_enabled?
        User.unviewed_message_user_ids.delete(user.id)
        next
      end

      # Fetch and delete unviewed message ids that are at least X hours old
      time = STALENESS_TIME.ago.to_i

      message_ids, _ = user.redis.multi do
        user.unviewed_message_ids.rangebyscore('-inf', time)
        user.unviewed_message_ids.remrangebyscore('-inf', time)
      end

      # Remove the user from the global list if needed
      User.check_unviewed_message_ids(user)

      # Email the user about his unviewed snaps
      user.email_notifier.notify_unviewed_snaps(message_ids)

      messages = message_ids.map{ |id| Message.new(id: id) }
      User.redis.hset(metrics_key, user.id, {messages_count: messages.size,
                      uniq_friends_count: messages.uniq(&:user_id).size,
                      message_ids: message_ids}.to_json)
    end
  end
end
