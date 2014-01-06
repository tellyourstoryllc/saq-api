class EmailNewMemberNotificationWorker < BaseWorker
  def self.category; :notification end
  def self.metric; :email_new_member end

  def perform(recipient_id, new_member_id, group_id)
    perform_with_tracking(recipient_id, new_member_id, group_id) do
      recipient = User.find(recipient_id)
      new_member = User.find(new_member_id)
      group = Group.find(group_id)

      EmailNotifier.new(recipient).notify_new_member!(new_member, group)
      true
    end
  end

  statsd_measure :perform, metric_prefix
end
