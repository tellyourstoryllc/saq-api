class SessionsController < ApplicationController
  skip_before_action :require_token, :create_or_update_device, only: :create


  def create
    @account = login_via_email_and_password || login_via_facebook

    if @account
      @current_user = @account.user
      IosDevice.create_or_assign!(@current_user, ios_device_params)
      render_json [current_user, @account]
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

    Account.joins(:emails).find_by(emails: {email: email}).try(:authenticate, password) if email.present? && password.present?
  end

  def login_via_facebook
    fb_id = params[:facebook_id]
    fb_token = params[:facebook_token]

    Account.find_by(facebook_id: fb_id).try(:authenticate_facebook, fb_token) if fb_id.present? && fb_token.present?
  end
end
