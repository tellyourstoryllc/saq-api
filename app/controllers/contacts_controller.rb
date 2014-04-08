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
    invited_users = contact_inviter.add_users(user_ids)
    invited_emails = contact_inviter.add_by_emails(emails, {skip_sending: params[:omit_email_invite], source: params[:source]})
    invited_phones = contact_inviter.add_by_phone_numbers(phone_numbers, phone_usernames, {skip_sending: params[:omit_sms_invite], source: params[:source]})

    users = invited_users | invited_emails.map(&:user) | invited_phones.map(&:user)
    render_json users, each_serializer: UserWithEmailsAndPhonesSerializer
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
