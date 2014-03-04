class ContactInviter
  include Peanut::Model
  attr_accessor :current_user


  def initialize(current_user)
    self.current_user = current_user
  end

  def add_users(user_ids)
    User.where(id: user_ids.map(&:to_s)).each do |user|
      add_with_reciprocal(user)
    end
  end

  def add_by_emails(emails_addresses, options = {})
    emails = []
    emails_addresses.each do |email_address|
      emails << add_by_email(email_address, options)
    end
    emails
  end

  def add_by_email(email_address, options = {})
    if Settings.enabled?(:queue) && Settings.enabled?(:background_invites)
      ContactInviterEmailWorker.perform_async(current_user.id, email_address, options)
    else
      add_by_email!(email_address, options)
    end
  end

  def add_by_email!(email_address, options = {})
    options = options.with_indifferent_access

    # Look for existing user/account
    address = Email.normalize(email_address)
    email = Email.find_by(email: address)
    account = email.try(:account)
    user = email.try(:user)
    new_user = user.nil?

    # If the user doesn't exist, create one
    unless account
      username = address.split('@').first + '_temp'
      account = Account.create!(user_attributes: {username: username}, emails_attributes: [{email: address}])
      user = account.user
      email = user.emails.find_by(email: address)
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_email: address,
                   new_user: new_user, can_log_in: account.can_log_in?, skip_sending: !!self.class.to_bool(options[:skip_sending]))

    # Add the new or existing user to my contacts and vice versa
    add_with_reciprocal(user)

    email
  end

  def add_by_phone_numbers(numbers, usernames, options = {})
    return [] if usernames.present? && numbers.size != usernames.size

    phones = []
    numbers.each_with_index do |number, i|
      phones << add_by_phone_number(number, usernames[i], options)
    end
    phones
  end

  def add_by_phone_number(number, username, options = {})
    if Settings.enabled?(:queue) && Settings.enabled?(:background_invites)
      ContactInviterPhoneWorker.perform_async(current_user.id, number, username, options)
    else
      add_by_phone_number!(number, username, options)
    end
  end

  def add_by_phone_number!(number, username, options = {})
    options = options.with_indifferent_access

    # Look for existing user/account
    number = Phone.normalize(number)
    phone = Phone.find_by(number: number)
    account = phone.try(:account)
    user = phone.try(:user)
    new_user = user.nil?

    # If the user doesn't exist, create one
    unless account
      account = Account.create!(user_attributes: {username: username}, phones_attributes: [{number: number}])
      user = account.user
      phone = user.phones.find_by(number: number)
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_phone: number,
                   new_user: true, can_log_in: account.can_log_in?, skip_sending: !!self.class.to_bool(options[:skip_sending]))

    # Add the new or existing user to my contacts and vice versa
    add_with_reciprocal(user)

    phone
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
      phones = Phone.includes(user: [:emails, :phones]).where(hashed_number: hashed_phone_numbers, verified: true)

      phones.each do |phone|
        added_users << phone.user
        add_with_reciprocal(phone.user)
      end
    end

    added_users
  end

  def facebook_autoconnect
    if Settings.enabled?(:queue)
      ContactInviterFacebookAutoconnectWorker.perform_async(current_user.id)
    else
      facebook_autoconnect!
    end
  end

  def facebook_autoconnect!
    current_user.account.facebook_friends_with_app.each do |u|
      add_with_reciprocal(u)
    end
  end
end
