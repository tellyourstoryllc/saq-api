class ContactInviter
  include Peanut::Model
  attr_accessor :current_user


  def initialize(current_user)
    self.current_user = current_user
  end

  def snapchat_friends_importer
    @snapchat_friends_importer ||= SnapchatFriendsImporter.new(current_user)
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
    emails.compact
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
      account = Account.create(user_attributes: {invite_type: :email}, emails_attributes: [{email: address}])
      return unless account.persisted?

      user = account.user
      email = user.emails.find_by(email: address)
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_email: address,
                   new_user: new_user, can_log_in: account.can_log_in?, skip_sending: !!self.class.to_bool(options[:skip_sending]),
                   source: options[:source])

    # Add the new or existing user to my contacts and vice versa
    add_with_reciprocal(user)

    email
  end

  def add_by_phone_numbers(numbers, usernames, options = {})
    users = []
    usernames.each_with_index do |username, i|
      users << add_by_phone_number(numbers[i], username, options)
    end
    users.compact
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

    if number.present? && username.blank?
      add_by_phone_number_only!(number, options)
    elsif number.blank? && username.present?
      add_by_username_only!(username, options)
    else
      add_by_phone_number_and_username!(number, username, options)
    end
  end

  def add_by_phone_number_only!(number, options)
    number = Phone.normalize(number)
    return if number.blank?

    # Look for existing user/account
    phone = Phone.find_by(number: number)
    account = phone.try(:account)
    user = phone.try(:user)
    new_user = user.nil?

    # If the user doesn't exist, create one
    unless account
      account = Account.create(user_attributes: {invite_type: :sms}, phones_attributes: [{number: number}])
      return unless account.persisted?

      user = account.user
      phone = user.phones.find_by(number: number)
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_phone: number,
                   new_user: new_user, can_log_in: account.can_log_in?, skip_sending: !!self.class.to_bool(options[:skip_sending]),
                   source: options[:source])

    # Add the new or existing user to my friends list
    add_friend(user)

    user
  end

  def add_by_username_only!(username, options)
    # Look for existing user/account
    user = User.find_by(username: username)
    account = user.try(:account)
    new_user = user.nil?

    # If the user doesn't exist, create one
    unless account
      account = Account.create(user_attributes: {username: username, invite_type: :sms})
      return unless account.persisted?

      user = account.user
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, new_user: new_user, can_log_in: account.can_log_in?,
                   skip_sending: !!self.class.to_bool(options[:skip_sending]), source: options[:source])

    # Add the new or existing user to my friends list
    add_friend(user)

    user
  end

  def add_by_phone_number_and_username!(number, username, options)
    number = Phone.normalize(number)
    return if number.blank?

    # Look for existing user/account
    user = User.find_by(username: username)
    account = user.try(:account)
    new_user = user.nil?

    # If the user doesn't exist, create one
    if account.nil?
      attrs = {user_attributes: {username: username, invite_type: :sms}}
      attrs[:phones_attributes] = [{number: number}] unless Phone.where(number: number).exists?

      account = Account.create(attrs)
      return unless account.persisted?

      user = account.user
      phone = user.phones.find_by(number: number)
    else
      # Let this silently fail if the phone record already exists
      phone = Phone.create(number: number, user: user)
    end

    Invite.create!(sender_id: current_user.id, recipient_id: user.id, invited_phone: number, new_user: new_user,
                   can_log_in: account.can_log_in?, skip_sending: !!self.class.to_bool(options[:skip_sending]), source: options[:source])

    # Add the new or existing user to my friends list
    add_friend(user)

    user
  end

  def add_with_reciprocal(other_user)
    return if current_user.id == other_user.id || User.blocked?(current_user, other_user)

    already_contacts = other_user.contact?(current_user)

    User.redis.multi do
      add_user(current_user, other_user)
      add_user(other_user, current_user)
    end

    other_user.mobile_notifier.create_ios_notifications("#{current_user.name} just added you", {r:'c'}) unless already_contacts
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

  def add_friend(user)
    snapchat_friends_importer.add_friend(user, :outgoing)
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
      current_user.phone_contacts << hashed_phone_numbers
      Phone.add_user_to_phone_contacts(current_user, hashed_phone_numbers)

      # Don't actually add contacts in SCP
      # Just use this for funnels & metrics
      #phones = Phone.includes(user: [:emails, :phones]).where(hashed_number: hashed_phone_numbers).verified

      #phones.each do |phone|
      #  added_users << phone.user
      #  add_with_reciprocal(phone.user)
      #end
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
