class UserAvatarVideosController < ApplicationController
  before_action :load_user

  def flag
    @avatar_video = @user.avatar_video
    render_success and return if @avatar_video.nil?

    @flag_reason = FlagReason.find(params[:flag_reason_id]) if params[:flag_reason_id].present?

    if @flag_reason.nil?
      render_error 'Invalid flag_reason_id'
    elsif @avatar_video.flag(current_user, @flag_reason)
      render_json @user
    else
      render_error
    end
  end


  private

  def load_user
    @user = User.find(params[:id])
  end
end
