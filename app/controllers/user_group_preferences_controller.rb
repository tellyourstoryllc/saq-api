class UserGroupPreferencesController < ApplicationController
  before_action :load_group, :load_preferences


  def show
    render_json @preferences
  end

  def update
    update_params.each do |k,v|
      @preferences.send("#{k}=", v)
    end

    if @preferences.save
      faye_publisher.publish_preferences(current_user, UserGroupPreferencesSerializer.new(@preferences).as_json)
      render_json @preferences
    else
      render_error @preferences.errors.full_messages
    end
  end


  private

  def load_group
    @group = current_user.groups.find(params[:group_id])
  end

  def load_preferences
    @preferences = UserGroupPreferences.find(current_user, @group)
  end

  def update_params
    params.permit(:server_all_messages_mobile_push)
  end
end
