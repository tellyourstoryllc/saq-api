class WidgetNotification
  # Attempt to send 15 mins after registration, then several times after that
  DELAYS = [15, 5, 5, 5, 8, 16, 32, 64]


  def self.schedule(user)
    info = user.widget_notification_info.all
    return if user.nil? || info['received'] || info['attempts_exhausted']

    attempts = info['attempts']
    delay = DELAYS[attempts.to_i]

    if delay
      user.widget_notification_info.incr('attempts')
      WidgetNotificationWorker.perform_at(delay.minutes.from_now, user.id)
    else
      user.widget_notification_info['attempts_exhausted'] = 1
    end
  end
end
