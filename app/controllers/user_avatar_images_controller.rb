class UserAvatarImagesController < ApplicationController
  before_action :load_user

  def flag
    @avatar_image = @user.avatar_image
    render_success and return if @avatar_image.nil?

    @flag_reason = FlagReason.find(params[:flag_reason_id]) if params[:flag_reason_id].present?

    if @flag_reason.nil?
      render_error 'Invalid flag_reason_id'
    else
      @avatar_image.flag(current_user, @flag_reason)
      render_json @user
    end
  end


  private

  def load_user
    @user = User.find(params[:id])
  end
end
