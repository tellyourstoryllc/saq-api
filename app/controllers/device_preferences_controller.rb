class DevicePreferencesController < ApplicationController

  def update
    raise ActiveRecord::RecordNotFound if current_device.nil?

    @preferences = current_device.preferences

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
    params.permit(:client, :server_mention, :server_one_to_one)
  end
end
