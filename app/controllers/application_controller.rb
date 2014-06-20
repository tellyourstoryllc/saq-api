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
    @current_device ||= if params[:device_id].present?
      IosDevice.find_by(device_id: params[:device_id])
    elsif params[:android_id].present?
      AndroidDevice.find_by(device_id: params[:android_id])
    end
  end

  def faye_publisher
    @faye_publisher ||= FayePublisher.new(params[:token])
  end

  def mixpanel
    @mixpanel ||= MixpanelClient.new(current_user)
  end

  def group_mixpanel
    @group_mixpanel ||= GroupMixpanelClient.new(current_user)
  end


  private

  def require_token
    # Note: Android depends on this error message, so don't change it
    render_error('Invalid token.', nil, status: :unauthorized) if current_user.nil?
  end

  def create_or_update_device
    return unless current_user

    if ios_device_params[:device_id].present?
      IosDevice.create_or_assign!(current_user, ios_device_params)
    elsif android_device_params[:android_id].present?
      AndroidDevice.create_or_assign!(current_user, android_device_params)
    end
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

  def android_device_params
    params.permit(:android_id, :v, :os_version)
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

  def remote_ip
    @remote_ip ||= secure_request? ? params[:ip] : request.remote_ip
  end

  def secure_request?
    params[:api_secret] == Rails.configuration.app['api']['request_secret']
  end

  def split_param(param_name)
    values = params[param_name] || []
    values = values.split(',', -1) unless values.is_a?(Array)
    values.map(&:strip)
  end

  def sent_snap_invites?
    Bool.parse(params[:sent_snap_invites]) && !Settings.enabled?(:disable_snap_invites) && Bool.parse(current_user.snap_invites_allowed.value)
  end

  def send_sms_invites?
    params[:omit_sms_invite] != 'true' && !Settings.enabled?(:disable_sms_invites) && Bool.parse(current_user.sms_invites_allowed.value)
  end

  def pagination_params
    params.permit(:limit, :offset)
  end

  def message_pagination_params
    params.permit(:limit, :below_rank, :below_message_id, :below_story_id, :above_comment_id)
  end

  def track_sc_users(users, phone_numbers = [])
    user_ids = users.map(&:id)
    return if user_ids.blank?

    current_user.snapchat_friend_ids << user_ids

    phone_numbers = phone_numbers.delete_if(&:blank?)
    current_user.snapchat_friend_phone_numbers << phone_numbers if phone_numbers.present?

    snap_invite = sent_snap_invites?
    users.each do |recipient|
      next if recipient.account.registered?

      sms_invite = send_sms_invites? && (phone = recipient.phones.find_by(number: phone_numbers))
      invite_channel = if snap_invite && sms_invite
                         'snap_and_sms'
                       elsif snap_invite
                         'snap'
                       elsif sms_invite
                         'sms'
                       end

      unless invite_channel.nil?
        recipient.last_invite_at = Time.current.to_i

        mp = MixpanelClient.new(recipient)
        mp.received_snap_invite(sender: current_user, invite_channel: invite_channel,
                                snap_invite_ad: current_user.snap_invite_ad, recipient_phone: phone)
      end
    end
  end

  def track_initial_sc_import
    return unless params[:initial_sc_import] == 'true'

    unless current_user.set_initial_snapchat_friend_ids_in_app.exists?
      user_ids_in_app = current_user.snapchat_friend_ids_in_app
      current_user.redis.multi do
        current_user.initial_snapchat_friend_ids_in_app << user_ids_in_app if user_ids_in_app.present?
        current_user.set_initial_snapchat_friend_ids_in_app = 1
      end
    end

    mixpanel.imported_snapchat_friends
    mixpanel.invited_snapchat_friends({}, {delay: 5.seconds}) if sent_snap_invites? || send_sms_invites?
  end
end
