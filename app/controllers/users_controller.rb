class UsersController < ApplicationController
  skip_before_action :require_token, :create_or_update_device, only: [:index, :create]


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
    @invite = Invite.find_by(invite_token: params[:invite_token]) if params[:invite_token].present?
    @current_user = @invite.try(:recipient)
    @account = @current_user.try(:account)

    # If an invite_token is included, just update that user
    if @current_user && @account && @account.no_login_credentials?
      @current_user.update!(user_params)
      @account.update!(account_params.merge(emails_attributes: [{email: params[:email]}]))

    # Otherwise, create a new user, account, etc.
    else
      @account = Account.create!(account_params.merge(user_attributes: user_params, emails_attributes: [{email: params[:email]}]))
      @current_user = @account.user
    end

    create_or_update_device

    @group = Group.create!(group_params.merge(creator_id: @current_user.id)) if group_params.present?

    mixpanel.user_registered(@current_user)
    group_mixpanel.group_created(@group) if @group

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
