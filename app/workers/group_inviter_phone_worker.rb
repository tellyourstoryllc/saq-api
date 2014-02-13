class GroupInviterPhoneWorker < BaseWorker
  def self.category; :invite end
  def self.metric; :group_phone end

  def perform(user_id, group_id, number, name)
    perform_with_tracking(user_id, group_id, number, name) do
      user = User.find(user_id)
      group = Group.find(group_id)
      GroupInviter.new(user, group).add_by_phone_number!(number, name)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
