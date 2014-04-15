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
    if @phone.verify_by_code!(params[:phone_verification_code])
      mixpanel.verified_phone(@phone, :entered_phone)
      render_json current_user
    else
      render_error
    end
  end


  private

  def load_phone
    number = Phone.normalize(params[:phone_number])

    if number
      @phone = Phone.find_or_initialize_by(number: number)
      @phone.user = current_user
    end
  end
end
