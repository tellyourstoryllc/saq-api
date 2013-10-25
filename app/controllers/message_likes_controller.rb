class MessageLikesController < ApplicationController
  before_action :load_message


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
      @message.group && @message.group.member_ids.include?(current_user.id)
  end
end
