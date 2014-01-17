class ContactsController < ApplicationController
  def index
    render_json current_user.paginated_contacts(pagination_params)
  end

  def add
    user_ids = split_param(:user_ids)
    emails = split_param(:emails)

    Contact.add_users(current_user, user_ids)
    Contact.add_by_emails(current_user, emails)

    render_json []
  end

  def remove
    user_ids = split_param(:user_ids)
    Contact.remove_users(current_user, user_ids)

    render_json User.where(id: user_ids)
  end


  private

  def pagination_params
    params.permit(:limit, :offset)
  end
end
