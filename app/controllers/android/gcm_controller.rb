class Android::GcmController < ApplicationController
  def set
    if params[:registration_id] && current_device && current_device.update!(registration_id: params[:registration_id])
      render_success
    else
      render_error
    end
  end

  def reset
    if current_device && current_device.update!(registration_id: nil)
      render_success
    else
      render_error
    end
  end
end
