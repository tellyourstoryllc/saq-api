class MobileNotifier
  attr_accessor :user
  NOTIFICATION_DELAYS = [5.minutes, 10.minutes, 20.minutes, 30.minutes, 1.hour, 2.hours, 4.hours, 8.hours, 24.hours] # approximate 2^n exponential backoff


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

  def notify(message)
    return if message.user_id == user.id

    user.unread_convo_ids << message.conversation.id

    notification_type = :all
    send_notification(message, notification_type)
  end

  def pushes_enabled?
    (user.ios_devices + user.android_devices).flatten.any?{ |d| d.preferences.server_pushes_enabled }
  end

  def create_ios_notification(ios_device, alert, custom_data = {}, options = {})
    return unless ios_device.can_send?

    options.reverse_merge!(badge: user.unread_convo_ids.size)
    options[:device_token] = ios_device.push_token

    n = ios_notifier.build_notification(alert, custom_data, options)
    saved = n.save!

    # Updates for content-available pushes
    if saved && options[:content_available]
      user.content_push_info['last_content_push_at'] = Time.current.to_i
      User.redis.incr("user::content_pushes_count:#{Time.zone.today}")
      StatsD.increment('content_available_pushes.server_sent')
    end

    saved
  end

  def create_android_notification(android_device, alert, custom_data = {}, options = {})
    return unless android_device.can_send?

    options.reverse_merge!(badge: user.unread_convo_ids.size)
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

  def send_notification(message, notification_type)
    convo = message.conversation
    custom_data = {}

    if convo.is_a?(Group)
      custom_data[:gid] = convo.id
    elsif convo.is_a?(OneToOne)
      custom_data[:oid] = convo.id
    end

    alert = notification_alert(message, notification_type)
    notified = false

    # Send to all iOS devices
    user.ios_devices.each do |ios_device|
      if ios_device.notify?(user, convo, message, notification_type)
        notified = !!create_ios_notification(ios_device, alert, custom_data)
      end
    end

    # Send to all Android devices
    user.android_devices.each do |android_device|
      if android_device.notify?(user, convo, message, notification_type)
        notified = !!create_android_notification(android_device, alert, custom_data)
      end
    end

    # Update digest info
    if notified && notification_type == :all
      user.mobile_digests_sent.incr
      user.last_mobile_digest_notification_at = Time.current.to_i
      user.delete_mobile_digest_data
    end

    # returns true if a notification was sent
    notified
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

    alert = "Your friend #{friend.username} just joined! Send a snap to say hi!"
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_forward(message, actor)
    return if message.user_id == actor.id

    alert = "#{actor.username} forwarded your #{message.message_attachment.media_type_name}"
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_like(message, actor)
    return if message.user_id == actor.id

    alert = "#{actor.username} liked your #{message.message_attachment.try(:media_type_name) || 'message'}"
    custom_data = {}

    create_ios_notifications(alert, custom_data)
    create_android_notifications(alert, custom_data)
  end

  def notify_content_available(options = {})
    options.reverse_merge!(sound: nil)
    options[:content_available] = true

    create_ios_notifications(nil, {}, options) do |ios_device|
      ios_device.client_version.to_i >= ContentNotifier::MIN_CLIENT_VERSION
    end
  end
end
