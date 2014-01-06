class IosNotifier
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def build_notification(alert, custom_data = {})
    attrs = {app: Rails.configuration.app['rapns']['app'], alert: alert, data: custom_data}
    notification = Rapns::Apns::Notification.new(attrs)
    Rails.logger.debug "Notification: #{notification}; payload_size: #{notification.payload_size}"

    # Truncate the alert if the total payload size is too big
    max_size = 256
    if notification.payload_size > max_size
      alert_size = notification.alert.size - (notification.payload_size - max_size)
      notification.alert = notification.alert.truncate(alert_size, {separator: ' '})
      Rails.logger.debug "Truncated payload_size: #{notification.payload_size}"
    end

    notification
  end

  def notify(message)
    return if message.user_id == user.id

    convo = message.conversation
    custom_data = {}

    if convo.is_a?(Group)
      notification_type = message.mentioned?(user) ? :mention : :all
      custom_data[:gid] = convo.id
    elsif convo.is_a?(OneToOne)
      notification_type = :one_to_one
      custom_data[:oid] = convo.id
    end

    if notification_type == :mention
      mentioned_name = message.mentioned_all? ? '@all' : 'you'
      alert = "#{message.user.name} mentioned #{mentioned_name} in the room \"#{message.group.name}\""
      alert << ": #{message.text}" if message.text.present?
    elsif notification_type == :one_to_one
      alert = message.text.present? ? "#{message.user.name}: #{message.text}" : "#{message.user.name} sent you a 1-1 message"
    elsif notification_type == :all
      media_type = message.message_attachment.try(:media_type)
      alert = if media_type.present?
                media_desc = case media_type
                             when 'image' then 'an image'
                             when 'video' then 'a video'
                             when 'audio' then 'an audio clip'
                             else 'a file'
                             end
                "#{message.user.name} uploaded #{media_desc} to the room \"#{message.group.name}\""
              elsif message.text.present?
                "(#{message.group.name}) #{message.user.name}: #{message.text}"
              end
    end

    notification = build_notification(alert, custom_data)

    user.ios_devices.each do |ios_device|
      if ios_device.notify?(user, convo, message, notification_type)
        n = notification.dup
        n.device_token = ios_device.push_token
        n.save!
      end
    end
  end

  def notify_new_member(member, group)
    return if member.id == user.id

    alert = "#{member.name} just joined the room #{group.name}. Go say hi!"
    custom_data = {gid: group.id}
    notification = build_notification(alert, custom_data)

    user.ios_devices.each do |ios_device|
      if ios_device.notify_new_member?(user)
        n = notification.dup
        n.device_token = ios_device.push_token
        n.save!
      end
    end
  end
end
