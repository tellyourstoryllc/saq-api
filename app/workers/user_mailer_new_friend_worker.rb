class UserMailerNewFriendWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email end

  def perform(user_id, friend_id, mutual)
    perform_with_tracking(user_id, friend_id, mutual) do
      user = User.find(user_id)
      friend = User.find(friend_id)
      user.email_notifier.notify_new_friend!(user, friend, mutual)

      true
    end
  end

  statsd_measure :perform, metric_prefix
end
