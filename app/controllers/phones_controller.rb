class PhonesController < ApplicationController
  before_action :load_phone


  def create
    if @phone
      HookClient.send_verification(@phone.number, @phone.verification_code) unless @phone.verified?
      render_json current_user
    else
      render_error
    end
  end

  def verify
    if @phone.verify_by_code!(params[:phone_verification_code])
      render_json current_user
    else
      render_error
    end
  end


  private

  def load_phone
    number = Phone.normalize(params[:phone_number])

    if number
      @phone = Phone.find_or_create_by(number: number) do |p|
        p.user = current_user
      end
    end
  end
end
