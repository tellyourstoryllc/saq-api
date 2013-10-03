class UsersController < ApplicationController
  skip_before_action :require_token, only: :create


  def create
    @user = User.create!(user_params)
    @group = Group.create!(group_params.merge(creator_id: @user.id)) if group_params.present?

    render_json [@user, @group].compact

  rescue ActiveRecord::RecordInvalid => e
    render_error
  end


  private

  def user_params
    params.permit(:name, :email, :password)
  end

  def group_params
    @group_params ||= params.permit(:group_name).tap do |hsh|
      group_name = hsh.delete(:group_name)
      hsh[:name] = group_name if group_name
    end
  end
end
