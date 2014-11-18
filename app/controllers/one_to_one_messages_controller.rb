class OneToOneMessagesController < ApplicationController
  before_action :load_one_to_one


  def index
    render_json @one_to_one.paginate_messages(message_pagination_params)
  end

  def create
    @message = Message.new(message_params)

    if @message.save
      unless params[:skip_publish]
        # TODO: authenticate as server
        # TODO: move to Sidekiq?

        data = MessageSerializer.new(@message).as_json
        users = [current_user, @one_to_one.other_user(current_user)]

        users.each do |user|
          faye_publisher.publish_one_to_one_message(user, data)
        end
      end

      # Potentially notify the other user, according to his status and preferences
      recipient = @one_to_one.other_user(current_user)
      recipient.send_snap_notifications(@message)

      # Track activity in Mixpanel
      mixpanel.daily_message_events(@message) unless importing_from_sc

      Robot.reply_to(current_user, @message)

      render_json @message
    else
      render_error @message.errors.full_messages
    end
  end


  private

  def load_one_to_one
    @one_to_one = OneToOne.new(id: params[:one_to_one_id])

    if @one_to_one.attrs.blank?
      raise Peanut::Redis::RecordNotFound unless @one_to_one.save
    else
      raise Peanut::Redis::RecordNotFound unless @one_to_one.authorized?(current_user)
    end
  end

  def message_params
    params.permit(:text, :mentioned_user_ids, {mentioned_user_ids: []}, :attachment_file, :attachment_metadata, :client_metadata).merge(one_to_one_id: @one_to_one.id, user_id: current_user.id)
  end
end
