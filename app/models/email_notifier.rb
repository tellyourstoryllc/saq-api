class EmailNotifier
  attr_accessor :user
  NOTIFICATION_DELAYS = [7.minutes, 15.minutes, 1.hour, 4.hours, 24.hours] # approximate 4^n exponential backoff


  def initialize(user)
    self.user = user
  end

  def digests_sent
    @digests_sent ||= user.email_digests_sent.value
  end

  def current_delay
    NOTIFICATION_DELAYS[digests_sent - 1] || NOTIFICATION_DELAYS.last
  end

  def last_notification_at
    return @last_notification_at if defined?(@last_notification_at)

    time = user.last_email_digest_notification_at.value
    @last_notification_at = Time.zone.at(time.to_i) if time
  end

  def next_digest_at
    last_notification_at + current_delay if last_notification_at
  end

  def self.job_token_key(user_id, digests_sent)
    "user:#{user_id}:email_digest:#{digests_sent}:job_token"
  end

  def self.group_chatting_member_ids_key(user_id, group_id)
    "user:#{user_id}:email_digest_group_chatting_members:#{group_id}"
  end

  def notify(message)
    return if message.user_id == user.id

    convo = message.conversation
    notification_type = :all

    # "one_to_one_email" is used as the general switch for controlling email notifcations 
    if user.preferences.server_one_to_one_email
      send_notification(notification_type, message)
    end
  end

  def send_notification(notification_type, message = nil, options = {})
    if Settings.enabled?(:queue) && options[:skip_queue].blank?
      EmailNotificationWorker.perform_in(1.minute, notification_type, message.id, user.id, user.computed_status)
    else
      send_notification!(notification_type, message, user.computed_status)
    end
  end

  def send_notification!(notification_type, message, status)
    MessageMailer.send(notification_type, message, user, status).deliver!
  end

  def notify_new_member(new_member, group)
    # Don't do anything
  end

  def notify_new_member!(new_member, group)
    # Don't do anything
  end
end
