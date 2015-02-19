class MobileNotifier
  attr_accessor :user
  NOTIFICATION_DELAYS = [5.minutes, 10.minutes, 20.minutes, 30.minutes, 1.hour, 2.hours, 4.hours, 8.hours, 24.hours] # approximate 2^n exponential backoff

  # Frequency is in minutes
  # Frequency of -1 means don't send any digests - send notifications for every story
  STORIES_DIGEST_FREQUENCIES = [
    -1,  # No digests; regular story notifications for every story
    480, # Max one digest notification per 8 hours
    1440 # Max one digest notification per 24 hours
  ]


  def initialize(user)
    self.user = user
  end

  def ios_notifier
    IosNotifier.new(user)
  end

  def android_notifier
    AndroidNotifier.new(user)
  end

  def digests_sent
    @digests_sent ||= user.mobile_digests_sent.value
  end

  def current_delay
    NOTIFICATION_DELAYS[digests_sent - 1] || NOTIFICATION_DELAYS.last
  end

  def last_notification_at
    return @last_notification_at if defined?(@last_notification_at)

    time = user.last_mobile_digest_notification_at.value
    @last_notification_at = Time.zone.at(time.to_i) if time
  end

  def next_digest_at
    last_notification_at + current_delay if last_notification_at
  end

  def self.job_token_key(user_id, digests_sent)
    "user:#{user_id}:mobile_digest:#{digests_sent}:job_token"
  end

  def self.group_chatting_member_ids_key(user_id, group_id)
    "user:#{user_id}:mobile_digest_group_chatting_member_ids:#{group_id}"
  end

  def notify_snap(message)
    return if message.user_id == user.id

    user.unread_convo_ids << message.conversation.id

    notification_type = :all
    send_snap_notification(message, notification_type)
  end

  def pushes_enabled?
    (user.ios_devices + user.android_devices).flatten.any?{ |d| d.preferences.server_pushes_enabled }
  end

  def create_ios_notification(ios_device, alert, custom_data = {}, options = {})
    return unless ios_device.can_send?

    options[:device_token] = ios_device.push_token

    n = ios_notifier.build_notification(alert, custom_data, options)
    saved = n.save!

    saved
  end

  def create_android_notification(android_device, alert, custom_data = {}, options = {})
    return unless android_device.can_send?

    options[:registration_ids] = android_device.registration_id

    n = android_notifier.build_notification(alert, custom_data, options)
    n.save!
  end

  # Send to all iOS devices for which the given block is true
  def create_ios_notifications(alert, custom_data = {}, options = {}, &block)
    user.ios_devices.each do |ios_device|
      create_ios_notification(ios_device, alert, custom_data, options) if !block_given? || block.call(ios_device)
    end
  end

  # Send to all Android devices for which the given block is true
  def create_android_notifications(alert, custom_data = {}, options = {}, &block)
    user.android_devices.each do |android_device|
      create_android_notification(android_device, alert, custom_data, options) if !block_given? || block.call(android_device)
    end
  end

  def send_snap_notification(message, notification_type)
    alert = notification_alert(message, notification_type)
    custom_data = {}

    convo = message.conversation

    if convo.is_a?(Group)
      custom_data[:gid] = convo.id
    elsif convo.is_a?(OneToOne)
      custom_data[:oid] = convo.id
    end

    # Send to all iOS devices
    user.ios_devices.each do |ios_device|
      if ios_device.notify?(user, convo, message, notification_type)
        create_ios_notification(ios_device, alert, custom_data)
      end
    end

    # Send to all Android devices
    user.android_devices.each do |android_device|
      if android_device.notify?(user, convo, message, notification_type)
        create_android_notification(android_device, alert, custom_data)
      end
    end

    # Update digest info
#    if notified && notification_type == :all
#      user.mobile_digests_sent.incr
#      user.last_mobile_digest_notification_at = Time.current.to_i
#      user.delete_mobile_digest_data
#    end
  end

  def add_to_imported_snaps_digest(message)
    status = user.misc['pending_imported_digest']

    # Add the message_id to the digest
    user.pending_imported_digest_message_ids << message.id unless status == 'cancelled'

    # Create a job to run if this is the first one in the import batch
    if status.nil?
      user.misc['pending_imported_digest'] = 1
      MobileImportedSnapsDigestNotificationWorker.perform_in(1.minute, user.id)
    end
  end

  def send_snap_digest_notifications
    pending_count = user.pending_imported_digest_message_ids.size
    return if pending_count == 0 # This shouldn't happen

    custom_data = {}

    if pending_count == 1
      message = Message.new(id: user.pending_imported_digest_message_ids.members.first)

      alert = notification_alert(message, :all)
      convo = message.conversation

      if convo.is_a?(Group)
        custom_data[:gid] = convo.id
      elsif convo.is_a?(OneToOne)
        custom_data[:oid] = convo.id
      end
    end

    create_ios_notifications(alert, custom_data){ |d| d.version_at_least?(:all_server_notifications) }
    create_android_notifications(alert, custom_data)
  end

  def notification_alert(message, notification_type)
    friendly_media_type = message.message_attachment.try(:friendly_media_type)
    if friendly_media_type.present?
      "#{message.user.name} sent #{friendly_media_type}"
    elsif message.text.present?
      "#{message.user.name}: #{message.text}" 
    else
      # Should never get here?
      "#{message.user.name} sent you a message"
    end
  end

  def notify_new_member(member, group)
    # Don't send any
  end

  def notify_friend_joined(friend)
    return if friend.id == user.id

    alert = "Your friend#{' ' + friend.public_username if friend.public_username} just joined! Send a snap to say hi!"
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_new_friend(friend, mutual)
    return if friend.id == user.id

    alert = "#{friend.public_username || 'Somebody'} just friended you#{' back' if mutual}!"
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_forward(message, actor)
    return if message.user_id == actor.id

    alert = "#{actor.public_username || 'Somebody'} forwarded your #{message.message_attachment.media_type_name}"
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_like(message, actor)
    return if message.user_id == actor.id

    description = message.story? ? 'story' : (message.message_attachment.try(:media_type_name) || 'message')
    alert = "Someone thanked you for sharing"
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_export(message, actor, method)
    return if message.user_id == actor.id
    Message.raise_if_invalid_method(method)

    msg_desc = message.story? ? 'story' : (message.message_attachment.try(:media_type_name) || 'message')
    alert = case method
            when 'screenshot' then "#{actor.public_username || 'Somebody'} took a screenshot of your #{msg_desc}"
            when 'library' then "#{actor.public_username || 'Somebody'} saved your #{msg_desc} to their camera roll"
            else "#{actor.public_username || 'Somebody'} shared your #{msg_desc}"
            end

    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def send_story_notification(ios_device, story)
    return if story.user_id == user.id

    alert = "Your friend has posted a story"
    custom_data = {stories: story.id}

    create_ios_notification(ios_device, alert, custom_data)
    #create_android_notifications(alert, custom_data)
  end

  def notify_story(story)
    return if story.user_id == user.id

    handle_digest = false
    frequency = user.stories_digest_frequency

    user.ios_devices.each do |ios_device|
      # If the device is old and the story was sent via SCP, send the notification
      if !ios_device.version_at_least?(:all_server_notifications)
        send_story_notification(ios_device, story) unless story.imported?

      # If the device is new but wasn't assigned to receive digests, send the notification
      elsif frequency == -1
        send_story_notification(ios_device, story)

      # If the device is new and was assigned to receive digests, handle the digest
      else
        handle_digest = true
      end
    end

    notify_or_add_to_stories_digest(story) if handle_digest
  end

  def add_to_stories_digest(story)
    user.pending_digest_story_ids << story.id
  end

  def send_stories_digest_notifications
    pending_count, _ = user.redis.multi do
      user.pending_digest_story_ids.size
      user.pending_digest_story_ids.del
      user.stories_digest_info['last_stories_digest_at'] = Time.current.to_i
    end

    alert = "You have #{pending_count} new #{pending_count == 1 ? 'story' : 'stories'}"
    custom_data = {}

    create_ios_notifications(alert, custom_data){ |d| d.version_at_least?(:all_server_notifications) }
    #create_android_notifications(alert, custom_data)
  end

  def notify_or_add_to_stories_digest(story)
    frequency = user.stories_digest_frequency
    last_stories_digest_at = user.stories_digest_info['last_stories_digest_at']

    # Add the story to the digest
    add_to_stories_digest(story)

    # If this is the user's first digest or his frequency has elapsed
    # since the last digest, send a story digest
    if last_stories_digest_at.nil? || Time.zone.at(last_stories_digest_at.to_i) < frequency.minutes.ago
      send_stories_digest_notifications
    end
  end

  def notify_story_comment(comment)
    return if comment.user_id == user.id

    friendly_media_type = comment.message_attachment.try(:comment_friendly_media_type)
    alert = if friendly_media_type.present?
              "Somebody posted #{friendly_media_type} comment on #{comment.conversation.user.public_username || 'someone'}'s story"
            else
              "Somebody commented on #{comment.conversation.user.public_username || 'someone'}'s story"
            end

    custom_data = {stories: comment.conversation.id}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_drip(drip_notification)
    return if drip_notification.blank?

    alert = drip_notification.push_text
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_widget
    alert = "Did you know you can see your most recent snaps and stories in the notification center? Turn on your iOS 8 widget today!"
    url = Rails.configuration.app['web']['url'] + '/widget-tutorial'
    custom_data = {object_type: 'command', instruction: 'webview', url: url}

    create_ios_notifications(alert, custom_data)
  end

  def notify_approved_story
    alert = "Your video has been approved."
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_censored_story(alert)
    return if alert.blank?

    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end
end
