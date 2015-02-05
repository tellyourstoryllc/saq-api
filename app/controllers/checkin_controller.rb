class CheckinController < ApplicationController
  skip_before_action :require_token, only: :index
  prepend_before_action :create_user, :require_signature, only: :index


  def index
    send_mixpanel_events
    add_to_daily_users
    increment_metrics

    objects = []
    config_class = case params[:client]
                   when 'web' then WebConfiguration
                   when 'ios' then IosConfiguration
                   when 'android' then AndroidConfiguration
                   else ClientConfiguration
                   end

    client_config = {object_type: 'configuration'}.merge(config_class.config)
    client_config[:phone_verification_destination] = Rails.configuration.app['hook']['invite_from'] if params[:client] == 'ios'
    client_config[:phone_verification_token] = current_device.fetch_phone_verification_token if current_device && !current_device.phones.verified.exists?
    client_config[:client_version] = current_device.try(:client_version)
    client_config[:has_push_token] = current_device.try(:has_auth?)
    client_config[:blacklisted_usernames] = Settings.get_list(:blacklisted_usernames)

    objects << client_config

    if current_user
      objects << current_user
      objects << current_user.account
      objects << current_user.preferences

      if !Settings.enabled?(:disable_snap_invites) && Bool.parse(current_user.snap_invites_allowed.value)
        snap_invite_ad = current_user.snap_invite_ad(params[:client])

        if snap_invite_ad
          client_config.merge!(snap_invite_image_url: snap_invite_ad.media_url,
                               snap_invite_image_text: snap_invite_ad.text_overlay,
                               snap_invite_url: snap_invite_ad.media_url,
                               snap_invite_text: snap_invite_ad.text_overlay)
        end
      end

      like_snap_template = current_user.like_snap_template
      client_config[:like_template] = like_snap_template.text_overlay if like_snap_template
    end

    objects << current_device.preferences if current_device
    objects += Emoticon.active
    objects += FlagReason.active

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

  def increment_metrics
    StatsD.increment('api_calls.checkin')
  end
end
