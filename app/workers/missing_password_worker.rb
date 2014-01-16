class MissingPasswordWorker < BaseWorker
  def self.category; :email end
  def self.metric; :missing_password end

  def perform(account_id)
    perform_with_tracking(account_id) do
      account = Account.find(account_id)
      account.send_missing_password_email!
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
