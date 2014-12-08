class MixpanelClient
  attr_accessor :mixpanel, :user


  def initialize(user = nil)
    self.mixpanel = Mixpanel::Tracker.new(self.class.token)
    self.user = user
  end

  def self.token
    @token ||= Rails.configuration.app['mixpanel']['token']
  end

  def common_properties
    connection = Thread.current[:conn]
    connection = case connection.to_s.downcase
                 when 'wifi' then 'Wifi'
                 end

    {'$created' => Time.current, 'Client' => Thread.current[:client], 'Client Version' => Thread.current[:client_version],
      'OS' => Thread.current[:os], 'Preferred Language' => Thread.current[:lang], 'Connection' => connection}
  end

  def default_properties
    properties = common_properties
    return properties if user.nil?

    friends_count, friends_bot_included, set_initial_exists, initial_friends_in_app_count, initial_bot_included = User.redis.pipelined do
      user.friend_ids.size
      user.friend_ids.include?(Robot.user.id)

      user.set_initial_friend_ids_in_app.exists?
      user.initial_friend_ids_in_app.size
      user.initial_friend_ids_in_app.include?(Robot.user.id)
    end

    if friends_count > 0
      friends_count -= 1 if friends_bot_included
    else
      friends_count = nil
    end

    if set_initial_exists
      initial_friends_in_app_count -= 1 if initial_bot_included
    else
      initial_friends_in_app_count = nil
    end

    drip_enabled = user.drip_notifications_enabled.value

    properties.merge!(
      'distinct_id' => user.id, '$created' => user.created_at, 'Name' => user.name,
      '$username' => user.username, 'Birthday' => user.birthday, 'Age' => user.age, 'Can Log In' => user.account.can_log_in?,
      'Time Zone' => user.account.time_zone, 'Status' => user.computed_status, 'Invited' => user.invited?,
      'Sent Messages' => user.metrics[:sent_messages_count].to_i,
      'Received Messages' => user.metrics[:received_messages_count].to_i,
      'Phone Contacts' => user.phone_contacts.size, 'Matching Phone Contacts' => user.matching_phone_contact_user_ids.size,
      'Friends' => friends_count, 'Initial Friends in App' => initial_friends_in_app_count,
      'Notifications Enabled' => user.mobile_notifier.pushes_enabled?,
      'Drip Notifications Enabled' => (!drip_enabled.blank? ? %w(1 2).include?(drip_enabled) : nil),
      'Rating' => user.app_reviews.latest.limit(1).pluck(:rating).first, 'Skipped Phone' => Bool.parse(user.skipped_phone.value),
      'Stories Digest Frequency' => user.stories_digest_frequency
    )

    properties.merge!('Friends w/ Phone' => user.friend_phone_numbers.size) if user.phone_contacts.exists?

    properties
  end

  def track_without_defaults(event_name, properties = {}, options = {})
    if Settings.enabled?(:queue)
      delay = options.delete(:delay)
      if delay.present?
        MixpanelWorker.perform_in(delay.to_i, event_name, properties, options)
      else
        properties['time'] ||= Time.current.to_i
        MixpanelWorker.perform_async(event_name, properties, options)
      end
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
    properties['time'] ||= Time.current.to_i
    mixpanel.track(event_name, properties, options)
  end

  def user_registered(user, properties = {})
    self.user = user
    track('User Registered', registered_properties(properties))
  end

  def checked_in
    last_checkin = user.last_mixpanel_checkin_at.get
    last_checkin = Time.zone.at(last_checkin.to_i) if last_checkin

    send_event = if last_checkin.nil?
                   true
                 else
                   registered_at = user.account.registered_at
                   time_since_registration = Time.current - registered_at
                   days_since_registration = (time_since_registration / 24.hours).floor
                   bucket_start = registered_at + days_since_registration.days
                   last_checkin < bucket_start
                 end

    if send_event
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
    # Disabled for now
    return

    track('Sent Photo Invite', invite_properties(invite))
  end

  def sent_native_photo_invite(properties)
    # Disabled for now
    return

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

  def existing_user_install
    track('Existing User Install')
  end

  def daily_message_events(message)
    if message.one_to_one
      recipient = message.one_to_one.other_user(message.user)

      if recipient.bot?
        sent_daily_message_to_bot(message)
      else
        sent_daily_message
      end
    else
      sent_daily_message
    end
  end

  def sent_daily_message
    last_message = user.last_mixpanel_message_at.get
    last_message = Time.zone.at(last_message.to_i) if last_message

    if last_message.nil? || last_message < 24.hours.ago
      user.last_mixpanel_message_at = Time.current.to_i
      track('Sent Daily Message')
    end
  end

  def sent_daily_message_to_bot(message)
    last_message = user.last_mixpanel_message_to_bot_at.get
    last_message = Time.zone.at(last_message.to_i) if last_message

    if last_message.nil? || last_message < 24.hours.ago
      user.last_mixpanel_message_to_bot_at = Time.current.to_i
      track('Sent Daily Message to Bot', sent_daily_message_to_bot_properties(message))
    end
  end

  def imported_snapchat_friends
    track('Imported Snapchat Friends', imported_friends_properties)
  end

  def invited_friends(properties = {}, options = {})
    track('Invited Friends', properties, options)
  end

  def shared_contacts
    track('Shared Contacts')
  end

  def received_snap_invite(properties)
    track('Received Snap Invite', received_snap_invite_properties(properties))
  end

  def received_like_snap(properties)
    track('Received Like Snap', received_like_snap_properties(properties))
  end

  def received_comment_snap(properties)
    track('Received Comment Snap', received_comment_snap_properties(properties))
  end

  def created_app_review
    track('Created App Review', created_app_review_properties)
  end


  private

  def registered_properties(properties)
    last_invite = user.last_invite_at.get
    last_invite = Time.zone.at(last_invite.to_i) if last_invite
    within_24h = last_invite && last_invite >= 24.hours.ago

    {'Within 24h of Invite' => within_24h, 'Clicked Invite Link' => user.clicked_invite_link.exists?}
  end

  def invite_properties(invite)
    channel = 'email' if invite.invited_email.present?

    if invite.invited_phone.present?
      channel = 'sms'
      phone_country_code = Phone.country_code(invite.invited_phone)
    end

    props = {
      'Invite ID' => invite.id, 'Invite Method' => 'api', 'Invite Channel' => channel,
      'Recipient ID' => invite.recipient_id, 'Recipient New User' => invite.new_user?,
      'Recipient Can Log In' => invite.can_log_in?, 'Group ID' => invite.group_id, 'Source' => invite.source
    }

    props['Phone Country'] = phone_country_code if phone_country_code
    props
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
    common_properties.merge!('distinct_id' => distinct_id)
  end

  def received_snap_properties(properties)
    sender = properties[:sender]
    return {} if sender.blank?

    friend_ids = sender.friend_ids_in_app
    friend_ids.delete(Robot.user.id)

    {'Sender ID' => sender.id, 'Sender Username' => sender.username,
      'Sender Friends in App' => friend_ids.size}
  end

  def received_snap_invite_properties(properties)
    props = received_snap_properties(properties)

    sender = properties[:sender]
    invite_channel = properties[:invite_channel] if %w(snap sms snap_and_sms email).include?(properties[:invite_channel])
    ad_name = properties[:snap_invite_ad].try(:name)
    phone_country_code = properties[:recipient_phone].try(:country_code)

    props['Invite Channel'] = invite_channel
    props['Snap Invite Ad'] = ad_name if %w(snap snap_and_sms).include?(invite_channel)
    props['Phone Country'] = phone_country_code if phone_country_code
    props['Mutual Friends'] = user.friend_ids.member?(sender.id)

    props
  end

  def received_like_snap_properties(properties)
    props = received_snap_properties(properties)
    props['Like Snap Template'] = properties[:like_snap_template].try(:name)
    props
  end

  def received_comment_snap_properties(properties)
    props = received_snap_properties(properties)
    props['Comment Snap Template'] = properties[:comment_snap_template].try(:name)
    props
  end

  def sent_daily_message_to_bot_properties(message)
    trigger = Robot.parse_trigger(message)
    robot_item = RobotItem.by_trigger(trigger).first
    {'Trigger' => trigger, 'Bot Reply' => robot_item.try(:name)}
  end

  def imported_friends_properties
    {'Snap Invites Allowed' => Bool.parse(user.snap_invites_allowed.value),
      'SMS Invites Allowed' => Bool.parse(user.sms_invites_allowed.value)}
  end

  def created_app_review_properties
    app_review = user.app_reviews.latest.first
    {'Feedback' => app_review.feedback, 'Will Write Review' => app_review.will_write_review}
  end
end
