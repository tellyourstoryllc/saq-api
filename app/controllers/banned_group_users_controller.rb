class BannedGroupUsersController < ApplicationController
  before_action :load_group
  before_action :load_user, except: :index


  def index
    if @group.can_view_bans?(current_user)
      render_json @group.paginated_banned_users(pagination_params)
    else
      render_error 'Sorry, you are not authorized.'
    end
  end

  def create
    if @group.can_ban?(current_user, @user)
      @group.ban(@user)
      render_success
    else
      render_error 'Sorry, you are not authorized to ban that user.'
    end
  end

  def destroy
    if @group.can_unban?(current_user, @user)
      @group.unban(@user)
      render_success
    else
      render_error 'Sorry, you are not authorized to unban that user.'
    end
  end


  private

  def load_group
    @group = Group.find(params[:id])
  end

  def load_user
    @user = User.find(params[:user_id])
  end
end
