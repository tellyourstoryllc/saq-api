class UsersController < ApplicationController
  skip_before_action :require_token, :create_or_update_device, only: :create


  def me
    render_json current_user
  end

  def index
    ids = split_param(:ids)
    ids = ids.first(20) # Max of 20 users at a time
    render_json User.find(ids)
  end

  def create
    @account = Account.create!(account_params.merge(user_attributes: user_params, emails_attributes: [{email: params[:email]}]))
    @current_user = @account.user
    create_or_update_device

    @group = Group.create!(group_params.merge(creator_id: @current_user.id)) if group_params.present?

    mixpanel.user_registered(@current_user)
    group_mixpanel.group_created(@group) if @group

    @account.send_welcome_email
    @account.send_missing_password_email

    FacebookUser.new(id: @account.facebook_id).fetch_friends if @account.facebook_id

    render_json [@current_user, @account, @group].compact
  end

  def update
    old_status = current_user.computed_status
    current_user.update!(update_user_params)

    new_status = current_user.computed_status(true)
    current_user.reset_digests_if_needed(old_status, new_status)

    faye_publisher.broadcast_to_contacts
    render_json current_user
  end


  private

  def account_params
    params.permit(:password, :facebook_id, :facebook_token)
  end

  def user_params
    params.permit(:name, :avatar_image_url)
  end

  def update_user_params
    params.permit(:name, :username, :status, :status_text, :avatar_image_file, :avatar_image_url)
  end

  def group_params
    @group_params ||= params.permit(:group_name).tap do |attrs|
      group_name = attrs.delete(:group_name)
      attrs[:name] = group_name if group_name
    end
  end
end
