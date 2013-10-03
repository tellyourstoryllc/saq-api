class UsersController < ApplicationController
  skip_before_action :require_token, only: :create


  def create
    @user = User.create!(user_params)
    @group = Group.create!(group_params.merge(creator_id: @user.id)) if group_params.present?

    render_json [@user, @group].compact

  rescue ActiveRecord::RecordInvalid => e
    render_error
  end

  def update
    current_user.update_attributes!(update_user_params)
    render_json current_user
  end


  private

  def user_params
    params.permit(:name, :email, :password)
  end

  def update_user_params
    attrs = params.permit(:name, :password, :status, :status_text)
    attrs.delete(:status) if attrs[:status] == 'idle'
    attrs
  end

  def group_params
    @group_params ||= params.permit(:group_name).tap do |hsh|
      group_name = hsh.delete(:group_name)
      hsh[:name] = group_name if group_name
    end
  end
end
