class UsersController < ApplicationController
  skip_before_action :require_token, :create_or_update_device, only: [:index, :username_status, :create_unregistered, :create]
  before_action :load_user, only: :flag


  def me
    render_json current_user
  end

  def index
    limit = 20 # Max of 20 users at a time

    usernames = split_param(:usernames)
    usernames = usernames.first(limit)

    friend_codes = split_param(:friend_codes)
    friend_codes = friend_codes.first(limit)

    users = []
    users += User.includes(:avatar_image, :avatar_video).where(username: usernames).order(:id) if usernames.present?
    users += User.includes(:avatar_image, :avatar_video).where(friend_code: friend_codes).order(:id) if friend_codes.present?
    render_json users.uniq.first(limit)
  end

  def username_status
    render_error('Missing username param.') and return if params[:username].blank?

    user = User.find_by(username: params[:username])

    status = if user.nil?
               :available
             elsif user.account.registered?
               :registered
             else
               :unclaimed
             end

    render_json status
  end

  def create_unregistered
    create_user!
    create_or_update_device
    render_json [current_user, current_user.account]
  end

  def create
    # First attempt to find an existing user by the given user token
    if current_user
      @account = current_user.account

    # If not found, try to find a user by the given invite token
    else
      @invite = Invite.find_by(invite_token: params[:invite_token]) if params[:invite_token].present?
      @current_user = @invite.try(:recipient)
      @current_user ||= User.find_by(username: user_params[:username])
      @account = @current_user.try(:account)
    end

    # If a user was found by a user token or invite token and he's not yet registered, just update that user
    if @current_user && @account && !@account.registered?
      @current_user.update!(user_params)
      attrs = account_params
      attrs[:emails_attributes] = [{email: params[:email]}] if params[:email].present?
      attrs[:phones_attributes] = [{number: params[:phone_number]}] if params[:phone_number].present? && !Phone.get(params[:phone_number])
      @account.update!(attrs)

    # Otherwise, create a new user, account, etc.
    else
      attrs = account_params.merge(user_attributes: user_params)
      attrs[:emails_attributes] = [{email: params[:email]}] if params[:email].present?
      attrs[:phones_attributes] = [{number: params[:phone_number]}] if params[:phone_number].present? && !Phone.get(params[:phone_number])
      @account = Account.create!(attrs)
      @current_user = @account.user
    end

    # Create or update device and group
    create_or_update_device
    @group = Group.create!(group_params.merge(creator_id: @current_user.id)) if group_params.present?

    @current_user.skipped_phone = params[:skipped_phone] if params[:skipped_phone].present?
    @current_user.set_stories_digest_frequency


    # Send events to Mixpanel
    mixpanel.user_registered(@current_user)
    group_mixpanel.group_created(@group) if @group

    #@account.send_welcome_email

    set_invite_flags

    # Fetch friends and autoconnect Facebook if needed
    #@account.facebook_user.try(:fetch_friends)
    #contact_inviter.facebook_autoconnect

    # Add robot as a contact and send initial messages
    #Robot.set_up_new_user(@current_user)

    # Assign whether or not the user should get new user drip notifications
    # and if so, schedule them all
    #DripNotification.set_up_new_user(@current_user, current_device)

    # Schedule widget notification (and reschedule if user is unavailable)
    #WidgetNotification.schedule(@current_user) if current_device && current_device.is_a?(IosDevice)

    current_device.existing_user_status = 'r' if current_device
    #@current_user.notify_friends

    # Take ownership of all phones the current device owns
    current_device.phones.each{ |p| p.update(user_id: @current_user.id) } if current_device

    # For each verified phone, add the new user as a contact for everyone
    # who has autoconnected his phone
    @current_user.phones.verified.each(&:add_as_contact_and_notify_friends)

    render_json [@current_user, @account, @group].compact
  end

  def update
    old_status = current_user.computed_status
    current_user.update!(update_user_params)

    new_status = current_user.computed_status(true)
    current_user.reset_digests_if_needed(old_status, new_status)
    current_user.reset_badge_count_if_needed(old_status, new_status)

    faye_publisher.broadcast_to_followers
    render_json current_user
  end

  def flag
    @flagged_screenshot = FlaggedScreenshot.create!(user_id: params[:id], flagger_id: current_user.id, image: params[:screenshot_file])
    @flagged_screenshot.flag(current_user)

    render_json @user
  end


  private

  def account_params
    params.permit(:password, :facebook_id, :facebook_token).merge(registered: true)
  end

  def user_params
    params.permit(:name, :username, :avatar_image_url, :avatar_video_file, :birthday, :gender, :latitude, :longitude, :location_name)
  end

  def update_user_params
    params.permit(:name, :username, :status, :status_text, :avatar_image_file, :avatar_image_url, :avatar_video_file, :birthday,
                  :latitude, :longitude, :location_name, :reset_friend_code, :one_to_one_privacy)
  end

  def group_params
    @group_params ||= params.permit(:group_name).tap do |attrs|
      group_name = attrs.delete(:group_name)
      attrs[:name] = group_name if group_name
    end
  end

  def contact_inviter
    @contact_inviter ||= ContactInviter.new(@current_user)
  end

  def set_invite_flags
    @current_user.snap_invites_allowed = (rand < Settings.get(:snap_invites_percentage).to_f) ? '1' : '0'
    @current_user.sms_invites_allowed = (rand < Settings.get(:sms_invites_percentage).to_f) ? '1' : '0'
  end

  def load_user
    @user = User.find(params[:id])
  end
end
