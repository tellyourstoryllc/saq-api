class BlockedUsersController < ApplicationController
  before_action :load_user, except: :index


  def index
    render_json current_user.paginated_blocked_users(pagination_params)
  end

  def create
    current_user.block(@user)
    render_success
  end

  def destroy
    current_user.unblock(@user)
    render_success
  end


  private

  def load_user
    @user = User.find(params[:id])
  end

  def pagination_params
    params.permit(:limit, :offset)
  end
end
