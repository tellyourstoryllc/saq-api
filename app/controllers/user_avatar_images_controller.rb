class UserAvatarImagesController < ApplicationController
  before_action :load_user

  def flag
    @avatar_image = @user.avatar_image
    render_success and return if @avatar_image.nil?

    if @avatar_image.flag(current_user)
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
