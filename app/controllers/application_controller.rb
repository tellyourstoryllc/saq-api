class ApplicationController < ActionController::Base
  before_action :require_token


  def current_user
    @current_user ||= ApiToken.select(:user_id).where(token: params[:token]).first.try(:user)
  end


  private

  def require_token
    render_error('Invalid token.', nil, status: :unauthorized) if current_user.nil?
  end

  def render_json(objects, options = {})
    render({json: objects}.merge(options))
  end

  def render_error(message = nil, code = nil, options = {})
    message ||= 'error'
    error = {message: message}
    error[:code] = code if code.present?

    render({json: {error: error}}.merge(options))
  end
end
