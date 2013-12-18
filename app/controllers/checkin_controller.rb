class CheckinController < ApplicationController
  def index
    mixpanel.checked_in

    objects = []

    meta = {
      object_type: 'meta'
    }

    objects << meta
    objects << current_user
    objects << current_user.account
    objects << current_user.preferences
    objects << current_device.preferences if current_device
    objects += Emoticon.active

    render_json objects
  end
end
