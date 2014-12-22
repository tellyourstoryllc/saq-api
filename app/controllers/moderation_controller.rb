class ModerationController < ApplicationController
  skip_before_action :require_token
  before_action :require_secure_request

  def callback
    model = params[:model_class].constantize.find(params[:model_id]) rescue nil

    if model
      if params[:passed].try(:include?, 'nudity')
        model.approve!
      elsif params[:failed].try(:include?, 'nudity')
        model.censor!
      end
      render_success
    else
      render_error("Could not find a record for the given model_class and model_id.")
    end
  end
end
