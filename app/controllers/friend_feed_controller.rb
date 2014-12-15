class FriendFeedController < ApplicationController
  before_action :load_friend_feed


  def index
    render_json @friend_feed.paginate_messages(message_pagination_params)
  end


  private

  def load_friend_feed
    @friend_feed = FriendFeed.new(id: current_user.id)
  end
end
