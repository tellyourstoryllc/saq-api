class StoryLikesController < ApplicationController
  before_action :load_story


  def index
    render_json @story.paginated_liked_users(pagination_params)
  end

  def create
    @story.like(current_user)
    render_json @story
  end


  private

  def load_story
    @story = Story.new(id: params[:id])
  end
end
