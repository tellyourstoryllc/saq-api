class SessionsController < ApplicationController
  skip_before_action :require_token, :create_or_update_device, only: :create


  def create
    @account = login_via_login_and_password || login_via_facebook || login_via_invite_token

    if @account
      @current_user = @account.user

      create_or_update_device
      check_existing_user_install

      render_json [current_user, @account, @group].compact
    else
      render_error('Incorrect credentials.', nil, {status: :unauthorized})
    end
  end

  def destroy
    current_device.try(:unassign!)
    render_json current_user
  end


  private

  def login_via_login_and_password
    login = params[:login]
    password = params[:password]

    if login.present? && password.present?
      account = if login.include?('@')
                  Account.joins(:emails).find_by(emails: {email: login})
                else
                  Account.joins(:user).find_by(users: {username: login})
                end
      account && account.password_digest.present? && account.authenticate(password)
    end
  end

  def login_via_facebook
    fb_id = params[:facebook_id]
    fb_token = params[:facebook_token]

    Account.find_by(facebook_id: fb_id).try(:authenticate_facebook, fb_token) if fb_id.present? && fb_token.present?
  end

  def login_via_invite_token
    if params[:invite_token].present?
      invite = Invite.find_by(invite_token: params[:invite_token])

      if invite
        recipient = invite.try(:recipient)
        account = recipient.try(:account)

        if account && !account.registered?
          #account.send_missing_password_email if account.no_login_credentials?
          invite.phone.try(:verify!, recipient)

          unless invite.clicked?
            recipient.clicked_invite_link = 1
            invite.update!(clicked: true)
            mixpanel = MixpanelClient.new(account.user)
            mixpanel.clicked_invite_link(invite)
          end

          account
        end
      end
    end
  end

  def check_existing_user_install
    existing_user_install = current_device && !current_device.existing_user_status.exists?

    if existing_user_install
      mixpanel.existing_user_install
      current_device.existing_user_status = 's'
    end
  end
end
