class CheckinController < ApplicationController
  def index
    mixpanel.checked_in

    objects = []

    config_class = case params[:client]
                   when 'web' then WebConfiguration
                   when 'ios' then IosConfiguration
                   else ClientConfiguration
                   end
    client_config = {object_type: 'configuration'}.merge(config_class.config)

    objects << client_config
    objects << current_user
    objects << current_user.account
    objects << current_user.preferences
    objects << current_device.preferences if current_device
    objects += Emoticon.active

    render_json objects
  end
end
