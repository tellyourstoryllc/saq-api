class CheckinController < ApplicationController
  skip_before_action :require_token, only: :index

  def index
    send_mixpanel_events
    add_to_daily_users

    objects = []
    config_class = case params[:client]
                   when 'web' then WebConfiguration
                   when 'ios' then IosConfiguration
                   when 'android' then AndroidConfiguration
                   else ClientConfiguration
                   end

    client_config = {object_type: 'configuration'}.merge(config_class.config)
    client_config.merge!(phone_verification_destination: Rails.configuration.app['hook']['invite_from']) if params[:client] == 'ios'

    objects << client_config

    if current_user
      objects << current_user
      objects << current_user.account
      objects << current_user.preferences

      snap_invite_ad = current_user.snap_invite_ad
      client_config.merge!(snap_invite_image_url: snap_invite_ad.media_url,
                           snap_invite_image_text: snap_invite_ad.text_overlay,
                           snap_invite_url: snap_invite_ad.media_url,
                           snap_invite_text: snap_invite_ad.text_overlay)
    end

    objects << current_device.preferences if current_device
    objects += Emoticon.active

    render_json objects
  end


  private

  def send_mixpanel_events
    if Thread.current[:client] == 'ios' && params[:device_id].present?
      device_id = params[:device_id]
      mixpanel.mobile_install(device_id) if IosDevice.mixpanel_installed_device_ids.add(device_id)
    elsif Thread.current[:client] == 'android' && params[:android_id].present?
      device_id = params[:android_id]
      mixpanel.mobile_install(device_id) if AndroidDevice.mixpanel_installed_device_ids.add(device_id)
    end

    mixpanel.checked_in if current_user
  end

  def add_to_daily_users
    return unless current_user

    key = User.daily_user_ids_in_eastern_key
    User.redis.sadd(key, current_user.id)
  end
end
