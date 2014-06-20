class UserPreferencesController < ApplicationController

  def update
    @preferences = current_user.preferences

    update_params.each do |k,v|
      @preferences.send("#{k}=", v)
    end

    if @preferences.save
      @preferences.update_blocks(params[:server_story_friends_to_block]) if params.has_key?(:server_story_friends_to_block)
      faye_publisher.publish_preferences(current_user, UserPreferencesSerializer.new(@preferences).as_json)
      render_json @preferences
    else
      render_error @preferences.errors.full_messages
    end
  end


  private

  def update_params
    params.permit(:client_web, :server_mention_email, :server_one_to_one_email,
                  :server_story_privacy, :server_disable_story_comments)
  end
end
