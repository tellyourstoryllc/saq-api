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


  private

  def send_verification
    HookClient.send_verification(@phone.number, @phone.verification_code) unless @phone.verified?
  end
end
