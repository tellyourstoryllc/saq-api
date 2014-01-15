class MixpanelClient
  attr_accessor :mixpanel, :user


  def initialize(user = nil)
    self.mixpanel = Mixpanel::Tracker.new(self.class.token)
    self.user = user
  end

  def self.token
    @token ||= Rails.configuration.app['mixpanel']['token']
  end

  def default_properties
    {
      'distinct_id' => user.id, '$created' => user.created_at, 'Client' => Thread.current[:client],
      'OS' => Thread.current[:os], 'Name' => user.name, '$username' => user.username,
      'Time Zone' => user.account.time_zone, 'Status' => user.computed_status, 'Invited' => user.invited?,
      'Groups' => user.group_ids.size, 'Created Groups' => user.live_created_groups_count,
      'Sent Messages' => user.metrics[:sent_messages_count].to_i,
      'Received Messages' => user.metrics[:received_messages_count].to_i
    }
  end

  def track(event_name, properties = {}, options = {})
    properties.reverse_merge!(default_properties)

    if Settings.enabled?(:queue)
      properties['time'] ||= Time.current.to_i
      MixpanelWorker.perform_async(event_name, properties, options)
    else
      track!(event_name, properties, options)
    end
  end

  def track!(event_name, properties = {}, options = {})
    mixpanel.track(event_name, properties, options)
  end

  def user_registered(user)
    self.user = user
    track('User Registered')
  end

  def checked_in
    last_checkin = user.last_mixpanel_checkin_at.get
    last_checkin = Time.zone.at(last_checkin.to_i) if last_checkin

    if last_checkin.nil? || last_checkin < 24.hours.ago
      user.last_mixpanel_checkin_at = Time.current.to_i
      track('Checked In')
    end
  end
end
