class GroupMessagesController < ApplicationController
  before_action :load_group


  def index
    render_json @group.paginate_messages(pagination_params)
  end

  def create
    @message = Message.new(message_params)

    if @message.save
      unless params[:skip_publish]
        faye_publisher.publish_to_group(@group, MessageSerializer.new(@message).as_json)
      end

      # Potentially notify each user, according to his status and preferences
      @group.members.each{ |user| user.send_notifications(@message) }

      # Track activity in Mixpanel
      group_mixpanel.sent_daily_message(@group)
      mixpanel.sent_daily_message

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
    params.permit(:text, :mentioned_user_ids, {:mentioned_user_ids => []}, :attachment_file, :client_metadata).merge(group_id: @group.id, user_id: current_user.id)
  end

  def pagination_params
    params.permit(:limit, :below_rank)
  end
end
