class MessagesController < ApplicationController
  before_action :load_message, only: :export


  def create
    group_ids = split_param(:group_ids)
    one_to_one_ids = split_param(:one_to_one_ids)
    messages = []

    # Create a message for each group
    valid_group_ids = group_ids & current_user.group_ids.members
    groups = valid_group_ids.present? ? Group.where(id: valid_group_ids) : []

    groups.each do |group|
      message = Message.new(message_params.merge(group_id: group.id))

      if message.save
        unless params[:skip_publish]
          faye_publisher.publish_to_group(group, MessageSerializer.new(message).as_json)
        end

        # Potentially notify each user, according to his status and preferences
        group.members.each{ |user| user.send_notifications(message) }

        # Track activity in Mixpanel
        group_mixpanel.sent_daily_message(group)
        mixpanel.daily_message_events(message)

        messages << message
      end
    end

    # Create a message for each 1-1
    one_to_one_ids.each do |one_to_one_id|
      one_to_one = load_one_to_one(one_to_one_id)
      next if one_to_one.nil?

      message = Message.new(message_params.merge(one_to_one_id: one_to_one.id))

      if message.save
        other_user = one_to_one.other_user(message.user)

        unless params[:skip_publish]
          data = MessageSerializer.new(message).as_json

          [current_user, other_user].each do |user|
            faye_publisher.publish_one_to_one_message(user, data)
          end
        end

        if !other_user.account.registered?
          send_invites(message, other_user)
        else
          # Potentially notify the other user, according to his status and preferences
          other_user.send_notifications(message)
        end

        # Track activity in Mixpanel
        mixpanel.daily_message_events(message)

        Robot.reply_to(current_user, message)

        messages << message
      end
    end

    # Send forward meta messages to the most recent and original users
    if messages.present? && messages.first.forward_message
      messages.first.send_forward_meta_messages
    end

    render_json messages
  end

  def export
    @message.record_export(current_user, params[:method])

    # Send export meta messages to the most recent and original users
    @message.send_export_meta_messages(current_user, params[:method])

    render_success
  end


  private

  def message_params
    params.permit(:text, :attachment_file, :attachment_metadata, :client_metadata, :expires_in,
                  :received, :original_message_id, :forward_message_id, :created_at).merge(user_id: current_user.id)
  end

  def load_one_to_one(one_to_one_id)
    one_to_one = OneToOne.new(id: one_to_one_id)

    if one_to_one.attrs.blank?
      one_to_one if one_to_one.save
    else
      one_to_one if one_to_one.authorized?(current_user)
    end
  end

  def send_invites(message, other_user)
    other_user.emails.each do |email|
      Invite.create!(sender_id: current_user.id, recipient_id: other_user.id, invited_email: email.email,
                     new_user: false, can_log_in: other_user.account.can_log_in?, message: message,
                     skip_sending: params[:omit_email_invite])
    end

    other_user.phones.each do |phone|
      Invite.create!(sender_id: current_user.id, recipient_id: other_user.id, invited_phone: phone.number,
                     new_user: false, can_log_in: other_user.account.can_log_in?, message: message,
                     skip_sending: !send_sms_invites?)
    end
  end

  def load_message
    @message = Message.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @message.attrs.exists? &&
      @message.conversation && @message.conversation.fetched_member_ids.include?(current_user.id)
  end
end
