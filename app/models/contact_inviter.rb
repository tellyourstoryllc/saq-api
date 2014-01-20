class ContactInviter
  attr_accessor :current_user


  def initialize(current_user)
    self.current_user = current_user
  end

  def add_users(user_ids)
    User.where(id: user_ids.map(&:to_s)).find_each do |user|
      add_with_reciprocal(user)
    end
  end

  def add_by_emails(emails_addresses)
    emails_addresses.each do |email_address|
      add_by_email(email_address)
    end
  end

  def add_by_email(email_address)
    if Settings.enabled?(:queue)
      ContactInviterEmailWorker.perform_async(current_user.id, email_address)
    else
      add_by_email!(email_address)
    end
  end

  def add_by_email!(email_address)
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

      Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_email: address, new_user: true)
      # TODO: log to mixpanel
      #mixpanel.
    end

    add_with_reciprocal(user)
  end

  def add_with_reciprocal(other_user)
    return if current_user.id == other_user.id || User.blocked?(current_user, other_user)

    User.redis.multi do
      add_user(current_user, other_user)
      add_user(other_user, current_user)
    end
  end

  def add_user(user, other_user)
    User.redis.multi do
      user.contact_ids << other_user.id
      other_user.reciprocal_contact_ids << user.id
    end
  end

  def remove_users(user_ids)
    User.where(id: user_ids.map(&:to_s)).find_each do |user|
      remove_user(current_user, user)
    end
  end

  def remove_user(user, other_user)
    User.redis.multi do
      user.contact_ids.delete(other_user.id)
      other_user.reciprocal_contact_ids.delete(user.id)
    end
  end
end
