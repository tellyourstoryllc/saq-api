class ApplicationController < ActionController::Base
  before_action :require_token
  rescue_from ActiveRecord::RecordNotFound, with: :render_404


  def current_user
    @current_user ||= ApiToken.select(:user_id).find_by(token: params[:token]).try(:user)
  end


  private

  def require_token
    render_error('Invalid token.', nil, status: :unauthorized) if current_user.nil?
  end

  def render_json(objects, options = {})
    object_array = Array[objects].flatten
    render({json: object_array}.merge(options))
  end

  def render_error(message = nil, code = nil, options = {})
    message ||= 'error'
    error = {message: message}
    error[:code] = code if code.present?

    render({json: {error: error}}.merge(options))
  end

  def render_404(exception)
    render_error 'Sorry, that could not be found.', nil, status: :not_found
  end
end
