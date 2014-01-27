class ContactsController < ApplicationController
  def index
    render_json current_user.paginated_contacts(pagination_params)
  end

  def add
    user_ids = split_param(:user_ids)
    emails = split_param(:emails)

    contact_inviter = ContactInviter.new(current_user)
    contact_inviter.add_users(user_ids)
    contact_inviter.add_by_emails(emails)

    normalized_emails = emails.map {|e| Email.normalize(e) }
    users = User.where(id: user_ids) | User.joins(:emails).where(emails: {email: normalized_emails})
    render_json users
  end

  def remove
    user_ids = split_param(:user_ids)
    ContactInviter.new(current_user).remove_users(user_ids)

    render_json User.where(id: user_ids)
  end


  private

  def pagination_params
    params.permit(:limit, :offset)
  end
end
