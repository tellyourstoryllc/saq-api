class AppReviewsController < ApplicationController
  def create
    @app_review = AppReview.new(app_review_params.merge(user_id: current_user.id, device_id: current_device.try(:id)))

    if @app_review.save!
      # TODO send to MP
      render_success
    end
  end


  private

  def app_review_params
    params.permit(:rating, :feedback, :will_write_review)
  end
end
