class EmailNotifier
  attr_accessor :user

  def initialize(user)
    self.user = user
  end

  def notify!(notification_type, message)
    return unless user.preferences.send("server_#{notification_type}_email")
    MessageMailer.send(notification_type, message, user, user.computed_status).deliver!
  end
end
