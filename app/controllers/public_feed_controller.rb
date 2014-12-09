class PublicFeedController < ApplicationController

  def index
    render_json PublicFeed.feed_api(current_user, feed_params)
  end

  private

  def feed_params
    params.slice(:limit, :offset, :sort, :latitude, :longitude, :radius)
  end

end
