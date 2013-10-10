class GroupsController < ApplicationController
  before_action :load_group, only: [:show, :update]


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
    render_json [@group, @group.members, @group.recent_messages]
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
    render_json [@group, @group.members, @group.recent_messages]
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
end
