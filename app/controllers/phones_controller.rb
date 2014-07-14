class PhonesController < ApplicationController
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

    render_json current_user
  end

  def verify
    number = Phone.normalize(params[:phone_number])
    render_error and return if number.blank?

    @phone = Phone.find_by(number: number)
    render_error and return if @phone.nil?

    if @phone.verify_by_code!(current_user, params[:phone_verification_code], {notify_friends: true})
      mixpanel.verified_phone(@phone, :entered_phone)
      render_json current_user
    else
      render_error
    end
  end

  def add
    phone_numbers = split_param(:phone_numbers).map{ |n| Phone.normalize(n) }
    phone_usernames = split_param(:phone_usernames)

    contact_inviter = ContactInviter.new(current_user)
    users = contact_inviter.add_by_phone_numbers(phone_numbers, phone_usernames, {skip_sending: !send_sms_invites?, source: params[:source]})

    track_sc_users(users, phone_numbers)

    render_json users, each_serializer: UserWithEmailsAndPhonesSerializer
  end


  private

  def send_verification
    HookClient.send_verification(@phone.number, @phone.verification_code) unless @phone.verified?
  end
end
