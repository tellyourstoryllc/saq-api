class UsersController < ApplicationController
  skip_before_action :require_token, :create_or_update_device, only: :create


  def me
    render_json current_user
  end

  def index
    limit = 20 # Max of 20 users at a time

    ids = split_param(:ids)
    ids = ids.first(limit)
    usernames = split_param(:usernames)
    usernames = usernames.first(limit)

    users = []
    users += User.includes(:avatar_image, :avatar_video).where(id: ids) if ids.present?
    users += User.includes(:avatar_image, :avatar_video).where(username: usernames) if usernames.present?
    render_json users.uniq.first(limit)
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

    @account.facebook_user.try(:fetch_friends)
    ContactInviter.new(@current_user).facebook_autoconnect

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
    params.permit(:name, :username, :avatar_image_url, :avatar_video_file)
  end

  def update_user_params
    params.permit(:name, :username, :status, :status_text, :avatar_image_file, :avatar_image_url, :avatar_video_file)
  end

  def group_params
    @group_params ||= params.permit(:group_name).tap do |attrs|
      group_name = attrs.delete(:group_name)
      attrs[:name] = group_name if group_name
    end
  end
end
