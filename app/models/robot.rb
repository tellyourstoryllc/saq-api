class Robot
  def self.username
    Rails.configuration.app['robot_username']
  end

  def self.user
    @user ||= User.find_by(username: username)
  end

  def self.bot?(u)
    return false

    user_id = u.is_a?(User) ? u.id : u
    user.try(:id) == user_id
  end

  def self.set_up_new_user(current_user)
    return if user.nil?

    add_friend(current_user)
    send_initial_messages(current_user)
  end
    
  def self.add_friend(current_user)
    User.redis.multi do
      current_user.add_friend_without_request(user)
      user.add_friend_without_request(current_user)
    end
  end

  def self.send_messages_by_trigger(current_user, trigger)
    one_to_one = OneToOne.new(creator_id: user.id, sender_id: current_user.id, recipient_id: user.id)

    items = RobotItem.by_trigger(trigger)
    items.each do |item|
      message = Message.new(one_to_one_id: one_to_one.id, user_id: user.id,
                            text: item.text, attachment_url: item.attachment_url)
      message.save

      one_to_one.publish_one_to_one_message(message, nil, skip_sender: trigger == 'intro')
    end
  end

  def self.send_arbitrary_message(recipient, msg_text, options = {})
    one_to_one = OneToOne.new(creator_id: user.id, sender_id: user.id, recipient_id: recipient.id)
    message = Message.new(one_to_one_id: one_to_one.id, user_id: user.id, text: msg_text)

    if message.save
      one_to_one.publish_one_to_one_message(message)

      if options[:mobile_only]
        recipient.send_mobile_only_notifications(message)
      else
        recipient.send_snap_notifications(message)
      end
    end
  end

  def self.send_initial_messages(current_user)
    one_to_one = OneToOne.new(creator_id: user.id, sender_id: user.id, recipient_id: current_user.id)
    one_to_one.save if one_to_one.attrs.blank?

    send_messages_by_trigger(current_user, 'intro')
  end

  def self.reply_to(current_user, message)
    convo = message.conversation
    return unless convo.is_a?(OneToOne) && message.user_id == current_user.id &&
      convo.other_user_id(current_user) == user.id

    trigger = parse_trigger(message)
    send_messages_by_trigger(current_user, trigger)
    record_invalid_bot_message(current_user, message)
  end

  def self.parse_trigger(message)
    msg_text = message.text.to_s.strip.downcase

    if RobotItem.valid_triggers.include?(msg_text)
      msg_text
    elsif msg_text.blank? && message.attachment_url.present?
      'attachment error'
    elsif msg_text =~ /^\d+$/
      'number error'
    else
      'general error'
    end
  end

  def self.record_invalid_bot_message(current_user, message)
    msg_text = message.text.to_s.strip.downcase
    valid_trigger = RobotItem.valid_triggers.include?(msg_text)

    unless valid_trigger
      BotMessage.create(user_id: current_user.id, message_id: message.id,
                        text: message.text, attachment_url: message.attachment_url,
                        attachment_preview_url: message.attachment_preview_url)
    end
  end
end
