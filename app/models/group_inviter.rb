class GroupInviter
  attr_accessor :current_user, :group


  def initialize(current_user, group)
    self.current_user = current_user
    self.group = group
  end

  def contact_inviter
    @contact_inviter ||= ContactInviter.new(current_user)
  end

  def add_users(user_ids)
    User.where(id: user_ids.map(&:to_s)).find_each do |user|
      add_to_group(user)
      contact_inviter.add_with_reciprocal(user)
    end
  end

  def add_by_emails(emails_addresses)
    emails_addresses.each do |email_address|
      add_by_email(email_address)
    end
  end

  def add_by_email(email_address)
    if Settings.enabled?(:queue)
      GroupInviterEmailWorker.perform_async(current_user.id, group.id, email_address)
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
      username = address.split('@').first
      account = Account.create!(user_attributes: {username: username}, emails_attributes: [{email: address}])
      user = account.user
    end

    add_to_group(user, {invited_email: address, new_user: new_user})

    # Add the new or existing user to my contacts and vice versa
    contact_inviter.add_with_reciprocal(user)
  end

  def add_by_phone_numbers(numbers, usernames)
    return if numbers.size != usernames.size

    numbers.each_with_index do |number, i|
      add_by_phone_number(number, usernames[i])
    end
  end

  def add_by_phone_number(number, username)
    if Settings.enabled?(:queue)
      GroupInviterPhoneWorker.perform_async(current_user.id, group.id, number, username)
    else
      add_by_phone_number!(number, username)
    end
  end

  def add_by_phone_number!(number, username)
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
    end

    add_to_group(user, {invited_phone: number, new_user: new_user})

    # Add the new or existing user to my contacts and vice versa
    contact_inviter.add_with_reciprocal(user)
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
