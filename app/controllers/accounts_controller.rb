class AccountsController < ApplicationController

  def update
    @account = current_user.account
    @account.update!(update_account_params)
    render_json @account
  end


  private

  def update_account_params
    params.permit(:password, :email, :new_password, :one_to_one_wallpaper_image_file).tap do |attrs|
      password = attrs.delete(:password)

      if @account.authenticate(password)
        attrs[:password] = attrs.delete(:new_password) if attrs[:new_password].present?
      else
        attrs.delete(:email)
        attrs.delete(:new_password)
      end
    end
  end
end
