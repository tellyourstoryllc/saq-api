class DevicePreferencesController < ApplicationController

  def update
    raise ActiveRecord::RecordNotFound if current_device.nil?

    @preferences = current_device.preferences

    update_params.each do |k,v|
      @preferences.send("#{k}=", v)
    end

    if @preferences.save
      # Send a checked in event the first time the user is prompted
      # to enable notifications, so we know their initial choice
      unless current_user.misc['sent_initial_checkin_event']
        current_user.misc['sent_initial_checkin_event'] = 1
        mixpanel.track('Checked In')
      end

      render_json @preferences
    else
      render_error @preferences.errors.full_messages
    end
  end


  private

  def update_params
    params.permit(:client, :server_mention, :server_one_to_one, :server_pushes_enabled)
  end
end
