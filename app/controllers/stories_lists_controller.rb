class StoriesListsController < ApplicationController
  before_action :load_stories_list, only: :show


  def show
    render_json @stories_list.paginate_messages(message_pagination_params)
  end


  private

  def load_stories_list
    @stories_list = StoriesList.new(creator_id: params[:user_id], viewer_id: current_user.id)

    if @stories_list.attrs.blank?
      raise Peanut::Redis::RecordNotFound unless @stories_list.save
    else
      raise Peanut::Redis::RecordNotFound unless @stories_list.authorized?(current_user)
    end
  end
end
