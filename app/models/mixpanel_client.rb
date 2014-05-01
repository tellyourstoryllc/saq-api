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
    properties = {'Client' => Thread.current[:client], 'OS' => Thread.current[:os]}

    if user
      properties.merge!(
        'distinct_id' => user.id, '$created' => user.created_at, 'Name' => user.name,
        '$username' => user.username, 'Can Log In' => user.account.can_log_in?,
        'Time Zone' => user.account.time_zone, 'Status' => user.computed_status, 'Invited' => user.invited?,
        'Groups' => user.group_ids.size, 'Created Groups' => user.live_created_groups_count,
        'Sent Messages' => user.metrics[:sent_messages_count].to_i,
        'Received Messages' => user.metrics[:received_messages_count].to_i,
        'Snap Invite Ad' => user.snap_invite_ad.try(:name), 'Snapchat Friends' => user.snapchat_friend_ids.size,
        'Phone Contacts' => user.phone_contacts.size
      )
    end

    properties
  end

  def track_without_defaults(event_name, properties = {}, options = {})
    if Settings.enabled?(:queue)
      properties['time'] ||= Time.current.to_i
      MixpanelWorker.perform_async(event_name, properties, options)
    else
      track!(event_name, properties, options)
    end
  end

  #def track_preferrably_with_defaults(event_name, properties = {}, options = {})
  #  properties.reverse_merge!(default_properties) if user.present?
  #  track_without_defaults(event_name, properties, options)
  #end

  def track(event_name, properties = {}, options = {})
    properties.reverse_merge!(default_properties)
    track_without_defaults(event_name, properties, options)
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

  def sent_invite(invite)
    track('Sent Invite', invite_properties(invite))
  end

  def sent_native_invite(properties)
    track('Sent Invite', native_invite_properties(properties))
  end

  def sent_photo_invite(invite)
    track('Sent Photo Invite', invite_properties(invite))
  end

  def sent_native_photo_invite(properties)
    track('Sent Photo Invite', native_invite_properties(properties))
  end

  def cancelled_native_invite(properties)
    track('Cancelled Invite', native_invite_properties(properties))
  end

  def clicked_invite_link(invite)
    track('Clicked Invite Link', invite_properties(invite))
  end

  def clicked_group_invite_link(properties)
    track('Clicked Invite Link', native_invite_properties(properties))
  end

  def joined_group(group)
    track('Joined Group', group_properties(group))
  end

  def verified_phone(phone, method_name)
    method = case method_name
             when :sent_sms then 'Sent SMS'
             when :entered_phone then 'Entered Phone'
             end

    track('Verified Phone', {'Phone ID' => phone.id, 'Verification Method' => method})
  end

  def mobile_install(device_id)
    track_without_defaults('Mobile Install', mobile_install_properties(device_id))
  end

  def sent_daily_message
    last_message = user.last_mixpanel_message_at.get
    last_message = Time.zone.at(last_message.to_i) if last_message

    if last_message.nil? || last_message < 24.hours.ago
      user.last_mixpanel_message_at = Time.current.to_i
      track('Sent Daily Message')
    end
  end

  def invited_snapchat_friends
    track('Invited Snapchat Friends')
  end

  def shared_contacts
    track('Shared Contacts')
  end


  private

  def invite_properties(invite)
    channel = 'email' if invite.invited_email.present?
    channel = 'sms' if invite.invited_phone.present?

    {
      'Invite ID' => invite.id, 'Invite Method' => 'api', 'Invite Channel' => channel,
      'Recipient ID' => invite.recipient_id, 'Recipient New User' => invite.new_user?,
      'Recipient Can Log In' => invite.can_log_in?, 'Group ID' => invite.group_id, 'Source' => invite.source
    }
  end

  def native_invite_properties(properties)
    invite_method = properties[:invite_method] if %w(api native).include?(properties[:invite_method])
    invite_channel = properties[:invite_channel] if %w(email sms).include?(properties[:invite_channel])
    source = properties[:source] if %w(signup home).include?(properties[:source])

    {
      'Invite Method' => invite_method, 'Invite Channel' => invite_channel, 'Recipients' => properties[:recipients],
      'Source' => source
    }
  end

  def group_properties(group)
    {
      'Group ID' => group.id, 'Group Created At' => group.created_at, 'Group Name' => group.name,
      'Group Creator ID' => group.creator_id, 'Group Members' => group.member_ids.size, 'Group Messages' => group.message_ids.size
    }
  end

  def mobile_install_properties(device_id)
    client = Thread.current[:client]
    distinct_id = "#{client}-#{device_id}"

    {
      'distinct_id' => distinct_id, '$created' => Time.zone.now, 'Client' => client, 'OS' => Thread.current[:os]
    }
  end
end
