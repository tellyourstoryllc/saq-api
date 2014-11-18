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

  def notify_snap(message)
    return if message.user_id == user.id

    convo = message.conversation
    notification_type = :all

    # "one_to_one_email" is used as the general switch for controlling email notifcations 
    if user.preferences.server_one_to_one_email
      send_snap_notification(notification_type, message)
    end
  end

  def send_snap_notification(notification_type, message = nil, options = {})
    data = {}
    data[:media_description] = message.message_attachment.try(:friendly_media_type)

    if Settings.enabled?(:queue) && options[:skip_queue].blank?
      MessageMailerWorker.perform_async(notification_type, user.id, message.id, data)
    else
      send_snap_notification!(notification_type, message, data)
    end
  end

  def send_snap_notification!(notification_type, message, data)
    MessageMailer.send(notification_type, message, user, data).deliver!
  end

  def notify_new_member(new_member, group)
    # Don't do anything
  end

  def notify_new_member!(new_member, group)
    # Don't do anything
  end

  def notify_new_snap(sender_username)
    sender = User.find_by(username: sender_username) if sender_username.present?
    return if sender.blank?

    if Settings.enabled?(:queue)
      SnapMailerNewSnapWorker.perform_async(user.id, sender.id)
    else
      notify_new_snap!(sender)
    end
  end

  def notify_new_snap!(sender)
    SnapMailer.new_snap(user, sender).deliver!
  end

  def notify_missed_sent_snaps
    return if user.daily_missed_sent_snaps_email.exists?

    if Settings.enabled?(:queue)
      SnapMailerMissedSentSnapsWorker.perform_async(user.id)
    else
      notify_missed_sent_snaps!
    end
  end

  def notify_missed_sent_snaps!
    return unless user.redis.set(user.daily_missed_sent_snaps_email.key, '1', {ex: 24.hours, nx: true})
    SnapMailer.missed_sent_snaps(user).deliver!
  end

  def notify_missed_received_snaps
    return if user.daily_missed_received_snaps_email.exists?

    if Settings.enabled?(:queue)
      SnapMailerMissedReceivedSnapsWorker.perform_async(user.id)
    else
      notify_missed_received_snaps!
    end
  end

  def notify_missed_received_snaps!
    return unless user.redis.set(user.daily_missed_received_snaps_email.key, '1', {ex: 24.hours, nx: true})
    SnapMailer.missed_received_snaps(user).deliver!
  end

  def notify_unviewed_snaps(message_ids)
    return if message_ids.blank?

    if Settings.enabled?(:queue)
      SnapMailerUnviewedSnapsWorker.perform_async(user.id, message_ids)
    else
      notify_unviewed_snaps!(message_ids)
    end
  end

  def notify_unviewed_snaps!(message_ids)
    messages = message_ids.map{ |id| Message.new(id: id) }
    SnapMailer.unviewed_snaps(user, messages).deliver!
  end

  def notify_forward(message, actor)
    return if message.user_id == actor.id

    if Settings.enabled?(:queue)
      MessageMailerForwardedMessageWorker.perform_async(message.id, actor.id)
    else
      notify_forward!(message, actor)
    end
  end

  def notify_forward!(message, actor)
    return if message.user_id == actor.id
    MessageMailer.forwarded_message(message, actor).deliver!
  end

  def notify_like(message, actor)
    return if message.user_id == actor.id

    if Settings.enabled?(:queue)
      MessageMailerLikedMessageWorker.perform_async(message.id, actor.id)
    else
      notify_like!(message, actor)
    end
  end

  def notify_like!(message, actor)
    return if message.user_id == actor.id
    MessageMailer.liked_message(message, actor).deliver!
  end

  def notify_story(story)
    return if story.user_id == user.id

    if Settings.enabled?(:queue)
      MessageMailerNewStoryWorker.perform_async(story.id, user.id)
    else
      notify_story!(story)
    end
  end

  def notify_story!(story)
    return if story.user_id == user.id
    MessageMailer.new_story(story, user).deliver!
  end

  def notify_story_comment(comment)
    return if comment.user_id == user.id

    if Settings.enabled?(:queue)
      MessageMailerStoryCommentWorker.perform_async(comment.id, user.id)
    else
      notify_story_comment!(comment)
    end
  end

  def notify_story_comment!(comment)
    return if comment.user_id == user.id
    MessageMailer.story_comment(comment, user).deliver!
  end

  def notify_drip(drip_notification)
    if Settings.enabled?(:queue)
      MessageMailerDripNotificationWorker.perform_async(drip_notification.id, user.id)
    else
      notify_drip!(drip_notification)
    end
  end

  def notify_drip!(drip_notification)
    MessageMailer.drip_notification(drip_notification, user).deliver!
  end

  def notify_widget
    if Settings.enabled?(:queue)
      AccountMailerWidgetNotificationWorker.perform_async(user.id)
    else
      notify_widget!
    end
  end

  def notify_widget!
    AccountMailer.widget_tutorial(user).deliver!
  end
end
