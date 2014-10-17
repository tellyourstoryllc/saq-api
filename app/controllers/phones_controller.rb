class PhonesController < ApplicationController
  skip_before_action :require_token, only: [:create, :verify, :confirm_activation]


  def create
    number = Phone.normalize(params[:phone_number])
    render_error and return if number.blank?

    @phone = Phone.find_or_initialize_by(number: number)

    if @phone.persisted?
      send_verification if @phone.user_id == current_user.id
    else
      @phone.user = current_user
      @phone.save!

      send_verification
    end

    render_json current_user.presence || []
  end

  def verify
    number = Phone.normalize(params[:phone_number])
    render_error and return if number.blank?

    @phone = Phone.find_by(number: number)
    render_error and return if @phone.nil?

    if @phone.verify_by_code!(current_user, current_device, params[:phone_verification_code], {notify_friends: true})
      mixpanel.verified_phone(@phone, :entered_phone) if current_user
      render_json current_user.presence || []
    else
      render_error
    end
  end

  def add
    phone_numbers = split_param(:phone_numbers).map{ |n| Phone.normalize(n) }
    phone_usernames = split_param(:phone_usernames)

    contact_inviter = ContactInviter.new(current_user)
    users = contact_inviter.add_by_phone_numbers(phone_numbers, phone_usernames, {skip_sending: !send_sms_invites?, source: params[:source]})

    render_json users, each_serializer: UserWithEmailsAndPhonesSerializer
  end

  def confirm_activation
    token = params[:phone_verification_token]
    klass = BaseDevice.device_class_for_token(token)
    device_id = BaseDevice.device_ids_by_phone_verification_token[token]
    device = klass.find_by(id: device_id) if device_id

    if device && device.phones.verified.exists?
      render_success
    else
      render_error
    end
  end


  private

  def send_verification
    HookClient.send_verification(@phone.number, @phone.verification_code) unless @phone.verified?
  end
end
