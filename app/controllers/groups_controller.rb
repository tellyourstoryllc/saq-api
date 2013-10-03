class GroupsController < ApplicationController

  def create
    @group = current_user.created_groups.create!(group_params)
    render_json @group

  rescue ActiveRecord::RecordInvalid => e
    render_error
  end


  private

  def group_params
    params.permit(:name)
  end
end
