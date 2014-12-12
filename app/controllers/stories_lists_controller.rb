class StoriesListsController < ApplicationController
  before_action :load_stories_list, only: :show


  def show
    render_json @stories_list.paginate_messages(message_pagination_params)
  end


  private

  def load_stories_list
    target = User.find(params[:id])

    list_class = if target.id == current_user.id
                   MyStoriesList
                 elsif target.friend_ids.include?(current_user.id)
                   FriendStoriesList
                 else
                   NonFriendStoriesList
                 end

    @stories_list = list_class.new(id: target.id, viewer_id: current_user.id)
    raise Peanut::Redis::RecordNotFound unless @stories_list.authorized?(current_user)
  end
end
