class ContactInviterEmailWorker < BaseWorker
  def self.category; :invite end
  def self.metric; :contact_email end

  def perform(user_id, email)
    perform_with_tracking(user_id, email) do
      user = User.find(user_id)
      ContactInviter.new(user).add_by_email!(email)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
