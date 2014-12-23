class ModerationController < ApplicationController
  skip_before_action :require_token
  before_action :require_secure_request

  def callback
    # Try to find the given ActiveRecord or Redis object
    model_class = params[:model_class].to_s.constantize
    model = if params[:model_id].present?
              if model_class.respond_to?(:find)
                model_class.find(params[:model_id])
              elsif model_class.ancestors.include?(Peanut::RedisModel)
                model_class.new(id: params[:model_id])
              end
            end

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
