class ContactsController < ApplicationController
  def index
    render_json current_user.paginated_contacts(pagination_params), each_serializer: UserWithEmailsAndPhonesSerializer
  end

  def add
    user_ids = split_param(:user_ids)
    emails = split_param(:emails)
    phone_numbers = split_param(:phone_numbers)
    phone_usernames = split_param(:phone_usernames)

    contact_inviter = ContactInviter.new(current_user)
    contact_inviter.add_users(user_ids)
    contact_inviter.add_by_emails(emails)
    contact_inviter.add_by_phone_numbers(phone_numbers, phone_usernames)

    normalized_emails = emails.map {|e| Email.normalize(e) }.compact
    normalized_numbers = phone_numbers.map {|n| Phone.normalize(n) }.compact

    users = []
    users = users | User.where(id: user_ids) if user_ids.present?
    users = users | User.joins(:emails).where(emails: {email: normalized_emails}) if normalized_emails.present?
    users = users | User.joins(:phones).where(phones: {number: normalized_numbers}) if normalized_numbers.present?

    render_json users
  end

  def remove
    user_ids = split_param(:user_ids)
    ContactInviter.new(current_user).remove_users(user_ids)

    render_json User.where(id: user_ids)
  end

  def autoconnect
    hashed_emails = split_param(:hashed_emails)
    hashed_phone_numbers = split_param(:hashed_phone_numbers)

    added_users = ContactInviter.new(current_user).autoconnect(hashed_emails, hashed_phone_numbers)
    render_json added_users, each_serializer: UserWithEmailsAndPhonesSerializer
  end


  private

  def pagination_params
    params.permit(:limit, :offset)
  end
end
