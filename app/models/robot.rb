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

  def self.send_initial_messages(current_user)
    one_to_one_id = OneToOne.id_for_user_ids(current_user.id, user.id)
    one_to_one = OneToOne.new(id: one_to_one_id)
    one_to_one.save if one_to_one.attrs.blank?

    initial_items = RobotItem.by_trigger('intro')
    initial_items.each do |item|
      message = Message.new(one_to_one_id: one_to_one_id, user_id: user.id,
                            text: item.text, attachment_url: item.attachment_url)
      message.save
    end
  end
end
