class ApplicationController < ActionController::Base


  private

  def render_json(objects, *options)
    render({json: objects}, *options)
  end

  def render_error(message = nil, code = nil)
    message ||= 'error'
    error = {message: message}
    error[:code] = code if code.present?

    render json: {error: error}
  end
end
