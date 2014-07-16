class StoryLikesController < ApplicationController
  before_action :load_story


  def index
    render_json @story.paginated_liked_users(pagination_params)
  end

  def create
    liked = @story.like(current_user)
    @story.user.send_like_notifications(@story, current_user) if liked

    if Bool.parse(params[:sent_snap])
      mp = MixpanelClient.new(@story.user)
      mp.received_like_snap(sender: current_user, like_snap_template: current_user.like_snap_template)
    end

    render_json @story
  end


  private

  def load_story
    @story = Story.new(id: params[:id])
  end
end
