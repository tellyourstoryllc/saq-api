class MessageLikesController < ApplicationController
  before_action :load_message


  def index
    render_json @message.paginated_liked_users(pagination_params)
  end

  def create
    @message.like(current_user)
    render_json @message
  end

  def destroy
    @message.unlike(current_user)
    render_json @message
  end


  private

  def load_message
    @message = Message.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @message.attrs.exists? &&
      @message.conversation && @message.conversation.fetched_member_ids.include?(current_user.id)
  end

  def pagination_params
    params.permit(:limit, :offset)
  end
end
