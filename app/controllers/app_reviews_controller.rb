class AppReviewsController < ApplicationController
  def create
    @app_review = AppReview.new(app_review_params.merge(user_id: current_user.id, device: current_device))

    if @app_review.save!
      mixpanel.created_app_review
      render_success
    end
  end


  private

  def app_review_params
    params.permit(:rating, :feedback, :will_write_review)
  end
end
