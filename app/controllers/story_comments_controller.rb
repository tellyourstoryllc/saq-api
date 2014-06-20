class StoryCommentsController < ApplicationController
  def index
    @story = Story.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound and return unless @story.attrs.exists? && @story.can_view_comments?(current_user)

    render_json @story.paginate_comments(message_pagination_params)
  end

  def create
    @story = Story.new(id: params[:id])

    raise Peanut::Redis::RecordNotFound and return unless @story.attrs.exists?
    raise Peanut::UnauthorizedError and return unless @story.can_create_comment?(current_user)

    @comment = Comment.new(comment_params.merge(collection_id: @story.id, collection_type: 'story'))

    if @comment.save
      render_json @comment
    else
      render_error
    end
  end

  def delete
    @story = Story.new(id: params[:story_id])
    raise Peanut::Redis::RecordNotFound and return unless @story.attrs.exists?

    @comment = Comment.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound and return unless @comment.attrs.exists? && @comment.can_delete?(current_user)

    @comment.delete
    render_json []
  end


  private

  def comment_params
    params.permit(:text, :attachment_file, :attachment_metadata, :client_metadata).merge(user_id: current_user.id)
  end
end
