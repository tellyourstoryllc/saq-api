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
    email = Email.get(email_address)

    # If it exists, just add him to my contacts
    if email
      user = email.user
      add_to_group(user)

    # If not, create a user for him, send an invite email, and add him to my contacts
    else
      address = Email.normalize(email_address)
      name = address.split('@').first
      account = Account.create!(user_attributes: {name: name}, emails_attributes: [{email: address}])
      user = account.user

      add_to_group(user, {invited_email: address, new_user: true})
    end

    contact_inviter.add_with_reciprocal(user)
  end

  def add_to_group(user, invite_attrs = {})
    return if current_user.id == user.id || User.blocked?(current_user, user)
    create_group_invite(user, invite_attrs)
    group.add_member(user)
  end

  def create_group_invite(user, attrs = {})
    unless group.member?(user)
      default_attrs = {sender_id: current_user.id, recipient_id: user.id, new_user: false, group_id: group.id}
      attrs.reverse_merge!(default_attrs)
      Invite.create!(attrs)
    end
  end
end
