class Contact
  def self.add_users(current_user, user_ids)
    User.where(id: user_ids.map(&:to_s)).find_each do |user|
      add_with_reciprocal(current_user, user)
    end
  end

  def self.add_by_emails(current_user, emails_addresses)
    emails_addresses.each do |email_address|
      add_by_email(current_user, email_address)
    end
  end

  def self.add_by_email(current_user, email_address)
    if Settings.enabled?(:queue)
      InviteContactEmailWorker.perform_async(current_user.id, email_address)
    else
      add_by_email!(current_user, email_address)
    end
  end

  def self.add_by_email!(current_user, email_address)
    # Look for existing user/account
    email = Email.get(email_address)

    # If it exists, just add him to my contacts
    if email
      user = email.user

    # If not, create a user for him, send an invite email, and add him to my contacts
    else
      address = Email.normalize(email_address)
      name = address.split('@').first
      account = Account.create!(user_attributes: {name: name}, emails_attributes: [{email: address}])
      user = account.user

      Invite.create!(sender_id: current_user.id, recipient_id: user.id, new_user: true, invited_email: address)
    end

    add_with_reciprocal(current_user, user)
  end

  def self.remove_users(current_user, user_ids)
    User.where(id: user_ids.map(&:to_s)).find_each do |user|
      remove_user(current_user, user)
    end
  end

  def self.add_with_reciprocal(user, other_user)
    return if User.blocked?(user, other_user) || user.id == other_user.id

    User.redis.multi do
      add_user(user, other_user)
      add_user(other_user, user)
    end
  end

  def self.add_user(user, other_user)
    User.redis.multi do
      user.contact_ids << other_user.id
      other_user.reciprocal_contact_ids << user.id
    end
  end

  def self.remove_user(user, other_user)
    User.redis.multi do
      user.contact_ids.delete(other_user.id)
      other_user.reciprocal_contact_ids.delete(user.id)
    end
  end
end
