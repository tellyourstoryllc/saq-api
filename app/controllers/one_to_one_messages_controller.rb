class OneToOneMessagesController < ApplicationController
  before_action :load_one_to_one


  def index
    render_json @one_to_one.paginate_messages(pagination_params)
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

  def load_one_to_one
    @one_to_one = OneToOne.new(id: params[:one_to_one_id])

    if @one_to_one.attrs.blank?
      raise Peanut::Redis::RecordNotFound unless @one_to_one.save
    else
      raise Peanut::Redis::RecordNotFound unless @one_to_one.authorized?(current_user)
    end
  end

  def message_params
    params.permit(:text, :mentioned_user_ids, {mentioned_user_ids: []}, :image_file, :client_metadata).merge(one_to_one_id: @one_to_one.id, user_id: current_user.id)
  end

  def pagination_params
    params.permit(:limit, :last_message_id)
  end
end
