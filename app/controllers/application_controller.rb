require 'active_record/validations'

class ApplicationController < ActionController::Base
  before_action :require_token, :create_or_update_device
  around_action :set_client
  rescue_from ActiveRecord::RecordNotFound, Peanut::Redis::RecordNotFound, with: :render_404
  rescue_from ActiveRecord::RecordInvalid, with: :render_422


  def current_user
    @current_user ||= begin
      user_id = User.user_ids_by_api_token[params[:token]]
      user = User.find_by(id: user_id) if user_id
      user_text = user ? "#{user.id} (#{user.name})" : '[not found]'
      logger.info "Current User: #{user_text}"
      user
    end
  end

  def current_device
    @current_device ||= IosDevice.find_by(device_id: params[:device_id]) if params[:device_id]
  end

  def faye_publisher
    @faye_publisher ||= FayePublisher.new(params[:token])
  end

  def mixpanel
    @mixpanel ||= MixpanelClient.new(current_user)
  end


  private

  def require_token
    render_error('Invalid token.', nil, status: :unauthorized) if current_user.nil?
  end

  def create_or_update_device
    IosDevice.create_or_assign!(current_user, ios_device_params) if current_user && ios_device_params.include?(:device_id)
  end

  def set_client
    Thread.current[:client] = params[:client]
    Thread.current[:os] = params[:os]

    begin
      yield
    ensure
      Thread.current[:client] = nil
      Thread.current[:os] = nil
    end
  end

  def ios_device_params
    params.permit(:device_id, :client_version, :os_version)
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

  def render_422(exception)
    render_error "Sorry, that could not be saved: #{exception}.", nil, status: :unprocessable_entity
  end
end
