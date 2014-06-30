class AccountMailerArbitraryWorker < BaseWorker
  def self.category; :email end
  def self.metric; :arbitrary end

  def perform(recipient_id, subject, msg, options = {})
    perform_with_tracking(recipient_id, subject, msg, options) do
      recipient = User.find(recipient_id)
      AccountMailer.arbitrary(recipient, subject, msg, options).deliver!
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
