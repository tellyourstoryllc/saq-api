class EmailNotifier
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def notify(message)
    convo = message.conversation
    notification_type = if convo.is_a?(Group) && message.mentioned?(user)
                          :mention
                        elsif convo.is_a?(OneToOne)
                          :one_to_one
                        end

    return unless notification_type && user.preferences.send("server_#{notification_type}_email")

    if Settings.enabled?(:queue)
      EmailNotificationWorker.perform_in(1.minute, notification_type, message.id, user.id, user.computed_status)
    else
      notify!(notification_type, message, user.computed_status)
    end
  end

  def notify!(notification_type, message, status)
    MessageMailer.send(notification_type, message, user, status).deliver!
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
