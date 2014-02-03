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
    address = Email.normalize(email_address)
    email = Email.find_by(email: address)
    account = email.try(:account)
    user = email.try(:user)
    new_user = user.nil?

    # If the user doesn't exist, create one
    unless account
      name = address.split('@').first
      account = Account.create!(user_attributes: {name: name}, emails_attributes: [{email: address}])
      user = account.user
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_email: address,
                   new_user: new_user, can_login: !account.no_login_credentials?)

    # Add the new or existing user to my contacts and vice versa
    add_with_reciprocal(user)
  end

  def add_by_phone_numbers(numbers, names)
    return if numbers.size != names.size

    numbers.each_with_index do |number, i|
      add_by_phone_number(number, names[i])
    end
  end

  def add_by_phone_number(number, name)
    if Settings.enabled?(:queue)
      ContactInviterPhoneWorker.perform_async(current_user.id, number, name)
    else
      add_by_phone_number!(number, name)
    end
  end

  def add_by_phone_number!(number, name)
    # Look for existing user/account
    number = Phone.normalize(number)
    phone = Phone.find_by(number: number)
    account = phone.try(:account)
    user = phone.try(:user)
    new_user = user.nil?

    # If the user doesn't exist, create one
    unless account
      account = Account.create!(user_attributes: {name: name}, phones_attributes: [{number: number}])
      user = account.user
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_phone: number,
                   new_user: true, can_login: !account.no_login_credentials?)

    # Add the new or existing user to my contacts and vice versa
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


  def autoconnect(hashed_emails, hashed_phone_numbers)
    added_users = []

    # TODO: wait until we verify emails
    #if hashed_emails.present?
    #  emails = Email.includes(:user).where(hashed_email: hashed_emails)

    #  emails.each do |email|
    #    added_users << email.user
    #    add_with_reciprocal(email.user)
    #  end
    #end

    if hashed_phone_numbers.present?
      phones = Phone.includes(:user).where(hashed_number: hashed_phone_numbers, verified: true)

      phones.each do |phone|
        added_users << phone.user
        add_with_reciprocal(phone.user)
      end
    end

    added_users
  end
end
