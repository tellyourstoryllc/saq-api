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
      # Notify the story's creator and all other users
      # who have commented on this story
      user_ids = [@story.user_id, *@story.commenter_ids].uniq
      user_ids.delete_if{ |id| id == current_user.id }

      User.where(id: user_ids).find_each do |user|
        user.send_story_comment_notifications(@comment)
      end

      if Bool.parse(params[:sent_snap])
        mp = MixpanelClient.new(@story.user)
        mp.received_comment_snap(sender: current_user, comment_snap_template: current_user.comment_snap_template)
      end

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
