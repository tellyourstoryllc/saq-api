class LogsController < ApplicationController
  def event
    case params[:event_name]
    when 'sent_invite' then mixpanel.sent_native_invite(property_params)
    when 'sent_photo_invite' then mixpanel.sent_native_photo_invite(property_params)
    when 'cancelled_invite' then mixpanel.cancelled_native_invite(property_params)
    when 'clicked_invite_link' then mixpanel.clicked_group_invite_link(property_params)
    end

    render_success
  end


  private

  def property_params
    params.permit(:invite_method, :invite_channel, :recipients)
  end
end
