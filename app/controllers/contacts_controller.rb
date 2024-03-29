class ContactsController < ApplicationController
  def index
    render_json current_user.paginated_contacts(pagination_params), each_serializer: UserWithEmailsAndPhonesSerializer
  end

  def add
    # TODO emails?
    phone_numbers = split_param(:phone_numbers).map{ |n| Phone.normalize(n) }

    contact_inviter = ContactInviter.new(current_user)
    users = contact_inviter.add_by_phone_numbers_only(phone_numbers, {skip_sending: !send_sms_invites?, source: params[:source]})
    users = User.includes(:account, :avatar_image, :avatar_video, :phones, :emails).where(id: users.map(&:id))

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

    user_ids = added_users.map(&:id)
    current_user.matching_phone_contact_user_ids << user_ids if user_ids.present?

    mixpanel.shared_contacts

    render_json added_users, each_serializer: UserWithEmailsAndPhonesSerializer
  end
end
