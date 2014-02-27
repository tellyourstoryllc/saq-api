class GroupInviterEmailWorker < BaseWorker
  def self.category; :invite end
  def self.metric; :group_email end

  def perform(user_id, group_id, email, options = {})
    perform_with_tracking(user_id, group_id, email, options) do
      user = User.find(user_id)
      group = Group.find(group_id)
      GroupInviter.new(user, group).add_by_email!(email, options)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
