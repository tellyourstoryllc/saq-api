class ApplicationController < ActionController::Base
  before_action :require_token
  rescue_from ActiveRecord::RecordNotFound, Peanut::Redis::RecordNotFound, with: :render_404


  def current_user
    @current_user ||= begin
      user_id = User.user_ids_by_api_token[params[:token]]
      user = User.find_by(id: user_id) if user_id
      user_text = user ? "#{user.id} (#{user.name})" : '[not found]'
      logger.info "Current User: #{user_text}"
      user
    end
  end

  def faye_publisher
    @faye_publisher ||= FayePublisher.new(params[:token])
  end


  private

  def require_token
    render_error('Invalid token.', nil, status: :unauthorized) if current_user.nil?
  end

  def render_json(objects, options = {})
    object_array = Array[objects].flatten
    render({json: object_array}.merge(options))
  end

  def render_success
    render json: []
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
