class Ios::ApnController < ApplicationController
  def set
    if params[:push_token] && current_device && current_device.update!(push_token: params[:push_token])
      render_success
    else
      render_error
    end
  end

  def reset
    if current_device && current_device.update!(push_token: nil)
      render_success
    else
      render_error
    end
  end
end
