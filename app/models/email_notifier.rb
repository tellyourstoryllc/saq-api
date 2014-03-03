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
    notification_type = if convo.is_a?(Group)
                          message.mentioned?(user) ? :mention : :all
                        elsif convo.is_a?(OneToOne)
                          :one_to_one
                        end

    if notification_type == :all
      notify_or_add_to_digest(message) if UserGroupPreferences.find(user, convo).server_all_messages_email
    elsif user.preferences.send("server_#{notification_type}_email")
      send_notification(notification_type, message)
    end
  end

  def notify_or_add_to_digest(message)
    # If this is the first notification of the cycle, send it immediately
    if digests_sent < 1
      send_notification(:all, message)

    # If not, prepare a digest notification
    else
      add_to_digest(message)

      # If the current delay has passed, send it immediately
      if Time.current >= next_digest_at
        send_notification(:all, message)

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
      user.email_digest_group_ids[message.group_id] = now
      user.redis.zadd(EmailNotifier.group_chatting_member_ids_key(user.id, message.group_id), now, message.user_id)
    end
  end

  # If there's not yet a job for the current delay interval, create one to run
  # at the time of the last notification + current delay
  def create_delayed_job(message)
    ttl = (next_digest_at + 5.minutes - Time.current).ceil
    key = EmailNotifier.job_token_key(user.id, digests_sent)

    token = SecureRandom.hex
    if User.redis.set(key, token, {nx: true, ex: ttl})
      EmailDigestNotificationWorker.perform_at(next_digest_at, user.id, token)
    end
  end

  def send_notification(notification_type, message = nil, options = {})
    if notification_type != :all
      if Settings.enabled?(:queue) && options[:skip_queue].blank?
        EmailNotificationWorker.perform_in(1.minute, notification_type, message.id, user.id, user.computed_status)
      else
        send_notification!(notification_type, message, user.computed_status)
      end
    else
      notification_subtype = nil
      data = {}

      # If this is the first digest since going unavailable, send the actual message content
      if digests_sent < 1
        notification_subtype = :content
        data[:media_description] = message.message_attachment.try(:friendly_media_type)
      else
        notification_subtype = :digest

        # Fetch the digest data
        group_ids = user.email_digest_group_ids.revrange(0, -1)
        grouped_member_ids = user.redis.pipelined do
          group_ids.each do |group_id|
            user.redis.zrevrange(EmailNotifier.group_chatting_member_ids_key(user.id, group_id), 0, -1)
          end
        end

        if grouped_member_ids.size == 1
          data[:group_id] = group_ids.first

          # Fetch the chatting members' names, ordered by most recent chatter first
          user_ids = grouped_member_ids.first
          field_order = user_ids.map{ |id| "'#{id}'" }.join(',')
          data[:names] = User.where(id: user_ids).order("FIELD(id, #{field_order})").pluck(:name)
        else
          data[:users_count] = grouped_member_ids.flatten.uniq.size

          # Fetch the groups' names, ordered by most recent activity first
          field_order = group_ids.map{ |id| "'#{id}'" }.join(',')
          data[:group_names] = Group.where(id: group_ids).order("FIELD(id, #{field_order})").pluck(:name)
        end
      end

      if Settings.enabled?(:queue) && options[:skip_queue].blank?
        MessageMailerWorker.perform_async(notification_subtype, user.id, message.id, data)
      else
        send_digest_notification!(notification_subtype, data, message)
      end
    end
  end

  def send_notification!(notification_type, message, status)
    MessageMailer.send(notification_type, message, user, status).deliver!
  end

  def send_digest_notification!(notification_subtype, data, message = nil)
    case notification_subtype.to_sym
    when :content then MessageMailer.all_content(message, user, data).deliver!
    when :digest then MessageMailer.all_digest(user, data).deliver!
    end

    # Update digest info
    user.email_digests_sent.incr
    user.last_email_digest_notification_at = Time.current.to_i
    user.delete_email_digest_data
  end

  def notify_new_member(new_member, group)
    if Settings.enabled?(:queue)
      EmailNewMemberNotificationWorker.perform_async(user.id, new_member.id, group.id)
    else
      notify_new_member!(new_member, group)
    end
  end

  def notify_new_member!(new_member, group)
    GroupMailer.new_member(user, new_member, group).deliver!
  end
end
