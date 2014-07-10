class ContentNotifier
  def send_notifications
    User.joins(:account).merge(Account.registered).includes(:ios_devices).find_each do |user|
      user.mobile_notifier.notify_content_available
    end
  end
end
