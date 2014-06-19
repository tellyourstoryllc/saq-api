class StoriesFeedsController < ApplicationController
  before_action :load_stories_feed, only: :show


  def show
    render_json @stories_feed.paginate_messages(message_pagination_params)
  end


  private

  def load_stories_feed
    @stories_feed = StoriesFeed.new(user_id: current_user.id)

    if @stories_feed.attrs.blank?
      raise Peanut::Redis::RecordNotFound unless @stories_feed.save
    end
  end
end
