class Robot
  def self.user
    @user ||= User.find_by(username: Rails.configuration.app['app_name_short'])
  end

  def self.set_up_new_user(current_user)
    return if user.nil?

    add_contact(current_user)
    send_initial_messages(current_user)
  end
    
  def self.add_contact(current_user)
    contact_inviter = ContactInviter.new(current_user)
    contact_inviter.add_with_reciprocal(user)
  end

  def self.send_messages_by_trigger(current_user, trigger)
    one_to_one_id = OneToOne.id_for_user_ids(current_user.id, user.id)

    items = RobotItem.by_trigger(trigger)
    items.each do |item|
      message = Message.new(one_to_one_id: one_to_one_id, user_id: user.id,
                            text: item.text, attachment_url: item.attachment_url)
      message.save
    end
  end

  def self.send_initial_messages(current_user)
    one_to_one_id = OneToOne.id_for_user_ids(current_user.id, user.id)
    one_to_one = OneToOne.new(id: one_to_one_id)
    one_to_one.save if one_to_one.attrs.blank?

    send_messages_by_trigger(current_user, 'intro')
  end

  def self.reply_to(current_user, message)
    convo = message.conversation
    return unless convo.is_a?(OneToOne) && message.user_id == current_user.id &&
      convo.other_user_id(current_user) == user.id

    trigger = message.text.to_s.strip

    if RobotItem.valid_triggers.include?(trigger)
      send_messages_by_trigger(current_user, trigger)
    else
      # TODO various error messages
    end
  end
end
