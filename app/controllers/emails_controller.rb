class EmailsController < ApplicationController
  before_action :load_email, only: [:update, :destroy]


  def index
    render_json current_user.emails
  end

  def create
    @email = current_user.emails.create!(account: current_user.account, email: params[:email])
    render_json @email
  end

  def update
    @email.update(update_params)
    render_json @email
  end

  def destroy
    if @email.destroy
      render_success
    else
      render_error @email.errors.full_messages
    end
  end


  private

  def load_email
    @email = current_user.emails.find(params[:id])
  end

  def update_params
    params.permit(:email)
  end
end
