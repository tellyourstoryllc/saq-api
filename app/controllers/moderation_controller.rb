class ModerationController < ApplicationController
  skip_before_action :require_token
  before_action :require_secure_request

  def callback
    # Try to find the given ActiveRecord or Redis object
    model_class = params[:model_class].to_s.constantize
    @model = if params[:model_id].present?
              if model_class.respond_to?(:find)
                model_class.find(params[:model_id])
              elsif model_class.ancestors.include?(Peanut::RedisModel)
                model_class.new(id: params[:model_id])
              end
            end

    if @model
      if params[:passed] && params[:passed].include?('video_approval') && @model.is_a?(Story)
        @model.approve!
      elsif params[:failed] && params[:failed].include?('video_approval') && @model.is_a?(Story)
        video_rejection = VideoRejection.create! do |vr|
          vr.story_id = @model.id
          vr.video_moderation_reject_reason_id = params[:reject_reason_id]
          vr.custom_message_to_user = params[:message_to_user]
        end

        notify_censored(video_rejection)

        @model.censor!
      end

      render_success
    else
      render_error("Could not find a record for the given model_class and model_id.")
    end
  end


  private

  def notify_censored(video_rejection)
    message = video_rejection.message_to_user

    if @model.review? && !@model.deleted?
      @model.user.send_censored_notifications(message)
    end
  end
end
