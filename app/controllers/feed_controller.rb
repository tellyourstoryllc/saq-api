class FeedController < ApplicationController

  def index
    render_json Feed.feed_api(current_user, feed_params)
  end

  private

  def feed_params
    params.permit(:limit, :offset, :sort, :latitude, :longitude, :radius)
  end

end
