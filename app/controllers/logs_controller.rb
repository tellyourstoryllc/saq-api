class LogsController < ApplicationController
  def event
    case params[:event_name]
    when 'sent_invite' then mixpanel.sent_native_invite(params.permit(:invite_method, :invite_channel, :recipients))
    when 'cancelled_invite' then mixpanel.cancelled_native_invite(params.permit(:invite_method, :invite_channel, :recipients))
    end

    render_success
  end
end
