class UserAvatarVideosController < ApplicationController
  before_action :load_user

  def flag
    @avatar_video = @user.avatar_video
    render_success and return if @avatar_video.nil?

    if @avatar_video.flag(current_user)
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
