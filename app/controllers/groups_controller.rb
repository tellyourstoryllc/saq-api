class GroupsController < ApplicationController

  def create
    @group = current_user.created_groups.create!(params.permit(:name))
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def update
    @group = current_user.groups.find(params[:id])
    @group.update_attributes!(update_group_params)
    render_json @group

  rescue ActiveRecord::RecordNotFound => e
    render_error 'Sorry, you need to be a member of that group to update it.', nil, {status: :unauthorized}

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end


  private

  def update_group_params
    params.permit(:topic).tap do |attrs|
      attrs[:name] = params[:name] if @group.admin?(current_user)
    end
  end
end
