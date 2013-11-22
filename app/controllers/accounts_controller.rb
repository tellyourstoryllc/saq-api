class AccountsController < ApplicationController
  skip_before_action :require_token, only: [:send_reset_email, :reset_password]


  def update
    @account = current_user.account

    password = params.delete(:password)

    if password
      if @account.authenticate(password)
        @authenticated = true
      else
        render_error('Incorrect credentials.', nil, {status: :unauthorized}) and return
      end
    end

    @account.update!(update_account_params)
    render_json @account
  end

  # Lost password
  def send_reset_email
    @account = Account.find_by(email: params[:login])

    if @account.nil?
      @user = User.find_by(username: params[:login])
      @account = @user.account if @user
    end

    if @account
      token = @account.generate_password_reset_token
      AccountMailer.password_reset(@account, token).deliver! if token
      render_json []
    else
      render_error("Sorry, we couldn't find your account. Please try again.")
    end
  end

  def reset_password
    @account = Account.find_by_password_reset_token(params[:token])

    if @account
      @account.update!(password: params[:new_password]) if params[:new_password].present?
      render_json @account
    else
      render_error("Sorry, that token does not exist or has expired.")
    end
  end


  private

  def update_account_params
    params.permit(:email, :new_password, :one_to_one_wallpaper_image_file).tap do |attrs|
      if @authenticated
        attrs[:password] = attrs.delete(:new_password) if attrs[:new_password].present?
      else
        attrs.delete(:email)
        attrs.delete(:new_password)
      end

      if attrs.has_key?(:one_to_one_wallpaper_image_file) && attrs[:one_to_one_wallpaper_image_file].blank?
        attrs[:delete_wallpaper] = true
      end
    end
  end
end
