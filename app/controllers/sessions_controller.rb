class SessionsController < ApplicationController
  skip_before_action :require_token, :create_or_update_device, only: :create


  def create
    @account = login_via_email_and_password || login_via_facebook || login_via_invite_token

    if @account
      @current_user = @account.user
      create_or_update_device

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

  def login_via_email_and_password
    email = params[:email]
    password = params[:password]

    if email.present? && password.present?
      account = Account.joins(:emails).find_by(emails: {email: email})
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
        account = invite.try(:recipient).try(:account)

        if account && account.no_login_credentials?
          account.send_missing_password_email
          invite.phone.try(:verify!)
          @group = invite.group

          account
        end
      end
    end
  end
end
