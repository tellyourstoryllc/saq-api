class InviteContactEmailWorker < BaseWorker
  def self.category; :invite end
  def self.metric; :contact_email end

  def perform(user_id, email)
    perform_with_tracking(user_id, email) do
      user = User.find(user_id)
      Contact.add_by_email!(user, email)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
