class ContactInviterFacebookAutoconnectWorker < BaseWorker
  def self.category; :facebook end
  def self.metric; :autoconnect end

  def perform(user_id)
    perform_with_tracking(user_id) do
      user = User.find(user_id)
      ContactInviter.new(user).facebook_autoconnect!
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
