class ContactInviterEmailWorker < BaseWorker
  def self.category; :invite end
  def self.metric; :contact_email end

  def perform(user_id, email, options = {})
    perform_with_tracking(user_id, email, options) do
      user = User.find(user_id)
      ContactInviter.new(user).add_by_email!(email, options)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
