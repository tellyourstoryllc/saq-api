class ContactInviterPhoneWorker < BaseWorker
  def self.category; :invite end
  def self.metric; :contact_phone end

  def perform(user_id, number, name, options = {})
    perform_with_tracking(user_id, number, name, options) do
      user = User.find(user_id)
      ContactInviter.new(user).add_by_phone_number!(number, name, options)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
