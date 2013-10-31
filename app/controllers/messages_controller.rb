class MessagesController < ApplicationController
  before_action :load_group


  def index
    render_json @group.paginate_messages(pagination_params)
  end

  def create
    @message = Message.new(message_params)

    if @message.save
      unless params[:skip_publish]
        endpoint = URI.parse(Rails.configuration.app['faye']['url'])
        message = {
          channel: "/groups/#{@group.id}/messages",
          data: MessageSerializer.new(@message).as_json,
          ext: {token: params[:token], persisted: true}
        }
        Net::HTTP.post_form(endpoint, message: message.to_json)
      end

      # Notify all Idle/Unavailable mentioned members
      @message.mentioned_users.each do |recipient|
        MessageMailer.mention(@message, recipient, recipient.computed_status).deliver! if recipient.idle_or_unavailable?
      end

      render_json @message
    else
      render_error @message.errors.full_messages
    end
  end


  private

  def load_group
    @group = current_user.groups.find(params[:group_id])
  end

  def message_params
    params.permit(:text, :mentioned_user_ids, :image_file).merge(group_id: @group.id, user_id: current_user.id)
  end

  def pagination_params
    params.permit(:limit, :last_message_id)
  end
end
