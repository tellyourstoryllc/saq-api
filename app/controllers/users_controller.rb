class UsersController < ApplicationController
  skip_before_action :require_token, only: :create


  def me
    render_json current_user
  end

  def create
    @current_user = User.create!(user_params)
    @group = Group.create!(group_params.merge(creator_id: @current_user.id)) if group_params.present?

    render_json [@current_user, @group].compact

  rescue ActiveRecord::RecordInvalid => e
    render_error e.message
  end

  def update
    current_user.update_attributes!(update_user_params)

    endpoint = URI.parse(Rails.configuration.app['faye']['url'])
    message = {channel: '/publish_to_contacts', ext: {token: params[:token]}}
    Net::HTTP.post_form(endpoint, message: message.to_json)

    render_json current_user
  end


  private

  def user_params
    params.permit(:name, :email, :password)
  end

  def update_user_params
    params.permit(:name, :password, :status, :status_text)
  end

  def group_params
    @group_params ||= params.permit(:group_name).tap do |attrs|
      group_name = attrs.delete(:group_name)
      attrs[:name] = group_name if group_name
    end
  end
end
