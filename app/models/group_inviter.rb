class GroupInviter
  include Peanut::Model
  attr_accessor :current_user, :group


  def initialize(current_user, group)
    self.current_user = current_user
    self.group = group
  end

  def contact_inviter
    @contact_inviter ||= ContactInviter.new(current_user)
  end

  def add_users(user_ids)
    User.where(id: user_ids.map(&:to_s)).each do |user|
      add_to_group(user)
      contact_inviter.add_with_reciprocal(user)
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
      GroupInviterEmailWorker.perform_async(current_user.id, group.id, email_address, options)
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

    add_to_group(user, {invited_email: address, new_user: new_user, skip_sending: !!self.class.to_bool(options[:skip_sending])})

    # Add the new or existing user to my contacts and vice versa
    contact_inviter.add_with_reciprocal(user)

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
      GroupInviterPhoneWorker.perform_async(current_user.id, group.id, number, username, options)
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

    add_to_group(user, {invited_phone: number, new_user: new_user, skip_sending: !!self.class.to_bool(options[:skip_sending])})

    # Add the new or existing user to my contacts and vice versa
    contact_inviter.add_with_reciprocal(user)

    phone
  end

  def add_to_group(user, invite_attrs = {})
    return if current_user.id == user.id || User.blocked?(current_user, user)
    create_group_invite(user, invite_attrs)
    group.add_member(user)
  end

  def create_group_invite(user, attrs = {})
    default_attrs = {sender_id: current_user.id, recipient_id: user.id,
      new_user: false, can_log_in: user.account.can_log_in?, group_id: group.id}
    attrs.reverse_merge!(default_attrs)
    Invite.create!(attrs)
  end
end
