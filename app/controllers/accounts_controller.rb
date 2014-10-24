class AccountsController < ApplicationController
  skip_before_action :require_token, only: [:send_reset_email, :send_reset_sms, :reset_password]


  def update
    @account = current_user.account
    new_password = params[:new_password]
    password = params.delete(:password)

    if new_password
      # If the account has a password, require verification of old password to change it
      if @account.password_digest.present?
        if @account.authenticate(password)
          @authenticated = true
        else
          render_error('Incorrect credentials.', nil, {status: :unauthorized}) and return
        end

      # If the account has no password, allow setting one with just with token
      else
        @authenticated = true
      end
    end

    @account.update!(update_account_params)
    faye_publisher.broadcast_account_to_one_to_one_users(current_user, AccountSerializer.new(@account).as_json) if update_account_params.include?(:one_to_one_wallpaper_image_file)

    render_json @account
  end

  # Send reset password link via email
  def send_reset_email
    @user = User.find_by(username: params[:login])
    @account = @user.account if @user
    @account = Account.joins(:emails).find_by(emails: {email: params[:login]}) if @account.nil?

    if @account
      token = @account.generate_password_reset_token
      AccountMailer.password_reset(@account, token).deliver! if token
      render_json []
    else
      render_error("Sorry, we couldn't find your account. Please try again.")
    end
  end

  # Send reset password link via SMS
  def send_reset_sms
    @user = User.find_by(username: params[:login])
    @account = @user.account if @user

    if @account.nil?
      @account = Account.joins(:emails).find_by(emails: {email: params[:login]})
      @user = @account.try(:user)
    end

    @phones = @user.try(:phones)

    if @phones.present?
      given_number = Phone.normalize(params[:phone_number])
      @phone = @phones.detect{ |p| given_number == p.number }
    end

    if @account && @phone
      token = @account.generate_password_reset_token
      HookClient.send_password_reset(@phone.number, token) if token
      render_json []
    else
      render_error("Sorry, we couldn't find your account. Please try again.")
    end
  end

  def reset_password
    @account = Account.find_by_password_reset_token(params[:token])

    if @account
      if params[:new_password].present?
        Account.delete_password_reset_token(params[:token]) if @account.update!(password: params[:new_password])
      end

      render_json @account
    else
      render_error("Sorry, that token does not exist or has expired.")
    end
  end


  private

  def update_account_params
    params.permit(:new_password, :time_zone, :one_to_one_wallpaper_image_file).tap do |attrs|
      if @authenticated
        attrs[:password] = attrs.delete(:new_password) if attrs[:new_password].present?
      else
        attrs.delete(:new_password)
      end

      if attrs.has_key?(:one_to_one_wallpaper_image_file) && attrs[:one_to_one_wallpaper_image_file].blank?
        attrs[:delete_wallpaper] = true
      end
    end
  end
end
