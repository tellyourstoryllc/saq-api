class GroupMixpanelClient < MixpanelClient
  attr_accessor :group


  def self.token
    @token ||= Rails.configuration.app['mixpanel']['group_token']
  end

  def default_properties
    {
      'distinct_id' => group.id, '$created' => group.created_at, 'Name' => group.name,
      'Creator ID' => group.creator_id, 'Members' => group.member_ids.size, 'Messages' => group.message_ids.size,
      'User ID' => user.id, 'User Created' => user.created_at, 'User Client' => Thread.current[:client],
      'User OS' => Thread.current[:os], 'User Name' => user.name, 'User Username' => user.username,
      'User Time Zone' => user.account.time_zone, 'User Status' => user.computed_status, 'User Invited' => user.invited?,
      'User Groups' => user.group_ids.size, 'User Created Groups' => user.live_created_groups_count,
      'User Sent Messages' => user.metrics[:sent_messages_count].to_i,
      'User Received Messages' => user.metrics[:received_messages_count].to_i
    }
  end

  def track(event_name, properties = {}, options = {})
    properties.reverse_merge!(default_properties)

    if Settings.enabled?(:queue)
      properties['time'] ||= Time.current.to_i
      GroupMixpanelWorker.perform_async(event_name, properties, options)
    else
      track!(event_name, properties, options)
    end
  end

  def group_created(group)
    self.group = group
    track('Group Created')
  end

  def daily_activity(group)
    self.group = group

    last_activity = group.last_mixpanel_activity_at.get
    last_activity = Time.zone.at(last_activity.to_i) if last_activity

    if last_activity.nil? || last_activity < 24.hours.ago
      group.last_mixpanel_activity_at = Time.current.to_i
      track('Daily Activity')
    end
  end

  def fetched_daily_messages(group)
    self.group = group
    daily_activity(group)

    last_fetched_messages = group.last_mixpanel_fetched_messages_at.get
    last_fetched_messages = Time.zone.at(last_fetched_messages.to_i) if last_fetched_messages

    if last_fetched_messages.nil? || last_fetched_messages < 24.hours.ago
      group.last_mixpanel_fetched_messages_at = Time.current.to_i
      track('Fetched Daily Messages')
    end
  end

  def sent_daily_message(group)
    self.group = group
    daily_activity(group)

    last_message = group.last_mixpanel_message_at.get
    last_message = Time.zone.at(last_message.to_i) if last_message

    if last_message.nil? || last_message < 24.hours.ago
      group.last_mixpanel_message_at = Time.current.to_i
      track('Sent Daily Message')
    end
  end
end
