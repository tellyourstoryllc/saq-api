class Ios::ApnController < ApplicationController
  def set
    if params[:push_token] && current_device && current_device.update!(push_token: Base64.decode64(params[:push_token].gsub(' ', '+')))
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
