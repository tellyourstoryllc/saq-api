class PhonesController < ApplicationController
  before_action :load_phone


  def create
    if @phone.save
      HookClient.send_verification(@phone.number, @phone.verification_code) unless @phone.verified?
      render_json current_user
    else
      render_error
    end
  end

  def verify
    if @phone.verify_by_code!(current_user, params[:phone_verification_code], {notify_friends: true})
      mixpanel.verified_phone(@phone, :entered_phone)
      render_json current_user
    else
      render_error
    end
  end


  private

  def load_phone
    number = Phone.normalize(params[:phone_number])
    @phone = Phone.find_or_initialize_by(number: number) if number
  end
end
