class ModerationController < ApplicationController
  skip_before_action :require_token
  before_action :require_secure_request

  def callback
    if (image_id = params[:image_id]) and (image = AvatarImage.find(image_id))
      if params[:passed].try(:include?, 'nudity')
        image.approve!
      elsif params[:failed].try(:include?, 'nudity')
        image.censor!
      end
      render_success
    else
      render_error("Expected image_id of an AvatarImage")
    end
  end

end
