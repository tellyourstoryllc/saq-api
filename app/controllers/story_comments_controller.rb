class StoryCommentsController < ApplicationController
  before_action :load_story, only: :create


  def create
    @comment = Comment.new(comment_params.merge(collection_id: @story.id, collection_type: 'story'))

    if @comment.save
      render_json @comment
    else
      render_error
    end
  end


  private

  def comment_params
    params.permit(:text, :attachment_file, :attachment_metadata, :client_metadata).merge(user_id: current_user.id)
  end

  def load_story
    @story = Story.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @story.attrs.exists? && @story.can_create_comment?(current_user)
  end
end
