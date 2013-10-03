class UsersController < ApplicationController
  def create
    @user = User.create!(user_params)
    render_json @user
  rescue ActiveRecord::RecordInvalid => e
    render_error
  end


  private

  def user_params
    params.permit(:name, :email, :password)
  end
end
