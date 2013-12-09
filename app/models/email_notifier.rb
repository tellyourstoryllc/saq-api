class EmailNotifier
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def notify!(message)
    convo = message.conversation
    notification_type = if convo.is_a?(Group) && message.mentioned?(user)
                          :mention
                        elsif convo.is_a?(OneToOne)
                          :one_to_one
                        end

    return unless notification_type && user.preferences.send("server_#{notification_type}_email")
    MessageMailer.send(notification_type, message, user, user.computed_status).deliver!
  end
end
