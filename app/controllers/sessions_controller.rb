class SessionsController < ApplicationController
  skip_before_action :require_token, only: :create


  def create
    @account = Account.find_by(email: params[:email])

    if @account.try(:authenticate, params[:password])
      @current_user = @account.user
      render_json [current_user, @account]
    else
      render_error 'Invalid credentials.'
    end
  end
end
