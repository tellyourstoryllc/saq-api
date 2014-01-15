class ContactsController < ApplicationController
  def index
    # TODO: paginate contacts?
  end

  def add
    user_ids = split_param(:user_ids)
    Contact.add_users(current_user, user_ids)

    render_json User.where(id: user_ids)
  end

  def remove
    user_ids = split_param(:user_ids)
    Contact.remove_users(current_user, user_ids)

    render_json User.where(id: user_ids)
  end
end
