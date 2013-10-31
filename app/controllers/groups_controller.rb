class GroupsController < ApplicationController
  before_action :load_group, only: [:show, :update, :leave]


  def index
    render_json current_user.groups.order(:name)
  end

  def create
    @group = current_user.created_groups.create!(params.permit(:name))
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def show
    render_json [@group, @group.members, @group.paginate_messages(pagination_params)]
  end

  def update
    @group.update_attributes!(update_group_params)
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def join
    @group = Group.find_by!(join_code: params[:join_code])
    @group.add_member(current_user)
    render_json [@group, @group.members, @group.paginate_messages(pagination_params)]
  end

  def leave
    @group.leave!(current_user)
    render_success
  end

  def is_member
    if Group.redis.sismember("group:#{params[:id]}:member_ids", current_user.id)
      render nothing: true
    else
      render nothing: true, status: :unauthorized
    end
  end


  private

  def load_group
    @group = current_user.groups.find(params[:id])
  end

  def update_group_params
    params.permit(:topic).tap do |attrs|
      attrs[:name] = params[:name] if @group.admin?(current_user)
    end
  end

  def pagination_params
    params.permit(:limit, :last_message_id)
  end
end
