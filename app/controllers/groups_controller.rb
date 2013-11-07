class GroupsController < ApplicationController
  before_action :load_group, only: [:show, :update, :leave]


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
    @group.update!(update_group_params)
    publish_to_group if @group.anything_changed
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def join
    @group = Group.find_by!(join_code: params[:join_code])

    # If this is a new member, publish the updated group to its channel
    if @group.add_member(current_user)
      publish_to_group
    end

    render_json [@group, @group.members, @group.paginate_messages(pagination_params)]
  end

  def leave
    # If the member successfully left the group, publish the updated group to its channel
    if @group.leave!(current_user)
      publish_to_group
    end

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

  def publish_to_group
    faye_publisher.publish_to_group(@group, GroupSerializer.new(@group).as_json)
  end
end
