class CheckinController < ApplicationController
  skip_before_action :require_token, only: :index

  def index
    mixpanel.checked_in if current_user
    objects = []

    config_class = case params[:client]
                   when 'web' then WebConfiguration
                   when 'ios' then IosConfiguration
                   else ClientConfiguration
                   end

    client_config = {object_type: 'configuration'}.merge(config_class.config)
    client_config.merge!(phone_verification_destination: Rails.configuration.app['hook']['invite_from']) if params[:client] == 'ios'

    objects << client_config

    if current_user
      objects << current_user
      objects << current_user.account
      objects << current_user.preferences
    end

    objects << current_device.preferences if current_device
    objects += Emoticon.active

    render_json objects
  end
end
