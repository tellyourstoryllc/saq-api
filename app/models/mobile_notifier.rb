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

    convo = message.conversation
    notification_type = if convo.is_a?(Group)
                          message.mentioned?(user) ? :mention : :all
                        elsif convo.is_a?(OneToOne)
                          :one_to_one
                        end

    if notification_type == :all
      notify_or_add_to_digest(message) if UserGroupPreferences.find(user, convo).server_all_messages_mobile_push
    else
      send_notification(message, notification_type)
    end
  end

  def notify_or_add_to_digest(message)
    # If this is the first notification of the cycle, send it immediately
    if digests_sent < 1
      send_notification(message, :all)

    # If not, prepare a digest notification
    else
      add_to_digest(message)

      # If the current delay has passed, send it immediately
      if Time.current >= next_digest_at
        send_notification(message, :all)

      # If not, add a delayed job if needed
      else
        create_delayed_job(message)
      end
    end
  end

  # Add this message's relevant data to the current digest
  def add_to_digest(message)
    now = Time.current.to_i

    user.redis.multi do
      user.mobile_digest_group_ids[message.group_id] = now
      user.redis.zadd(self.class.group_chatting_member_ids_key(user.id, message.group_id), now, message.user_id)
    end
  end

  # If there's not yet a job for the current delay interval, create one to run
  # at the time of the last notification + current delay
  def create_delayed_job(message)
    ttl = (next_digest_at + 5.minutes - Time.current).ceil
    key = self.class.job_token_key(user.id, digests_sent)

    token = SecureRandom.hex
    if User.redis.set(key, token, {nx: true, ex: ttl})
      MobileDigestNotificationWorker.perform_at(next_digest_at, user.id, message.id, token)
    end
  end

  def create_ios_notification(ios_device, alert, custom_data)
    n = ios_notifier.build_notification(alert, custom_data)
    n.device_token = ios_device.push_token
    n.save!
  end

  def create_android_notification(android_device, alert, custom_data)
    n = android_notifier.build_notification(alert, custom_data)
    n.registration_ids = android_device.registration_id
    n.save!
  end

  # Send to all iOS devices for which the given block is true
  def create_ios_notifications(alert, custom_data, &block)
    user.ios_devices.each do |ios_device|
      create_ios_notification(ios_device, alert, custom_data) if block.call(ios_device)
    end
  end

  # Send to all Android devices for which the given block is true
  def create_android_notifications(alert, custom_data, &block)
    user.android_devices.each do |android_device|
      create_android_notification(android_device, alert, custom_data) if block.call(android_device)
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
        create_ios_notification(ios_device, alert, custom_data)
        notified = true
      end
    end

    # Send to all Android devices
    user.android_devices.each do |android_device|
      if android_device.notify?(user, convo, message, notification_type)
        create_android_notification(android_device, alert, custom_data)
        notified = true
      end
    end

    # Update digest info
    if notified && notification_type == :all
      user.mobile_digests_sent.incr
      user.last_mobile_digest_notification_at = Time.current.to_i
      user.delete_mobile_digest_data
    end
  end

  def notification_alert(message, notification_type)
    case notification_type
    when :mention
      mentioned_name = message.mentioned_all? ? '@all' : 'you'
      "#{message.user.name} mentioned #{mentioned_name} in the room \"#{message.group.name}\": #{message.text}"
    when :one_to_one
      message.text.present? ? "#{message.user.name}: #{message.text}" : "#{message.user.name} sent you a 1-1 message"
    when :all
      # If this is the first digest since going unavailable, send the actual message content
      if digests_sent < 1
        media_type = message.message_attachment.try(:media_type)

        if media_type.present?
          media_desc = case media_type
                       when 'image' then 'an image'
                       when 'video' then 'a video'
                       when 'audio' then 'an audio clip'
                       else 'a file'
                       end
          "#{message.user.name} shared #{media_desc} in the room \"#{message.group.name}\""
        elsif message.text.present?
          "#{message.user.name} said \"#{message.text}\" in the room \"#{message.group.name}\""
        end

      # Else send a summary of what happened since the last digest notification
      else
        # Fetch the digest data
        group_ids = user.mobile_digest_group_ids.revrange(0, -1)
        grouped_member_ids = user.redis.pipelined do
          group_ids.each do |group_id|
            user.redis.zrevrange(MobileNotifier.group_chatting_member_ids_key(user.id, group_id), 0, -1)
          end
        end

        if grouped_member_ids.size == 1
          # Fetch the chatting members' names, ordered by most recent chatter first
          user_ids = grouped_member_ids.first
          field_order = user_ids.map{ |id| "'#{id}'" }.join(',')
          names = User.where(id: user_ids).order("FIELD(id, #{field_order})").pluck(:name)
          group_name = Group.find(group_ids.first).name

          case names.size
          when 1 then "#{names.first} is chatting in the room \"#{group_name}\""
          when 2 then "#{names.first} and #{names.last} are chatting in the room \"#{group_name}\""
          else "#{names.shift}, #{names.shift}, and #{names.size} other#{'s' unless names.size == 1} are chatting in the room \"#{group_name}\""
          end
        else
          # Fetch the groups' names, ordered by most recent activity first
          users_count = grouped_member_ids.flatten.uniq.size
          field_order = group_ids.map{ |id| "'#{id}'" }.join(',')
          group_names = Group.where(id: group_ids).order("FIELD(id, #{field_order})").pluck(:name)

          "#{users_count} #{users_count == 1 ? 'person is' : 'people are'} chatting in #{group_names.size} room#{'s' unless group_names.size == 1}: #{group_names.to_sentence}"
        end
      end
    end
  end

  def notify_new_member(member, group)
    return if member.id == user.id

    alert = "#{member.name} just joined the room #{group.name}. Go say hi!"
    custom_data = {gid: group.id}

    create_ios_notifications(alert, custom_data) do |ios_device|
      ios_device.notify_new_member?(user)
    end

    create_android_notifications(alert, custom_data) do |android_device|
      android_device.notify_new_member?(user)
    end
  end
end
