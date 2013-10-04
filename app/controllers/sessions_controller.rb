class SessionsController < ApplicationController
  skip_before_action :require_token, only: :create


  def create
    @current_user = User.find_by(email: params[:email])

    if @current_user.try(:authenticate, params[:password])
      render_json @current_user
    else
      render_error 'Invalid credentials.'
    end
  end
end
