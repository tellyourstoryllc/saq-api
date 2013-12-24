class MessageLikesController < ApplicationController
  before_action :load_message


  def index
    render_json @message.paginated_liked_users(pagination_params)
  end

  def create
    @message.like(current_user)
    publish_updated_message
    render_json @message
  end

  def destroy
    @message.unlike(current_user)
    publish_updated_message
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

  def publish_updated_message
    convo = @message.conversation

    if convo.is_a?(Group)
      faye_publisher.publish_to_group(convo, MessageSerializer.new(@message).as_json)
    elsif convo.is_a?(OneToOne)
      data = MessageSerializer.new(@message).as_json

      users = [current_user, convo.other_user(current_user)]
      users.each do |user|
        faye_publisher.publish_one_to_one_message(user, data)
      end
    end
  end
end
