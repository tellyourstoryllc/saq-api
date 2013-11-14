class PreferencesController < ApplicationController

  def update
    @preferences = current_user.preferences

    update_params.each do |k,v|
      @preferences.send("#{k}=", v)
    end

    if @preferences.save
      render_json @preferences
    else
      render_error @preferences.errors.full_messages
    end
  end


  private

  def update_params
    params.permit(:client_web, :client_ios, :server_mention_email, :server_mention_ios,
                  :server_one_to_one_email, :server_one_to_one_ios)
  end
end
