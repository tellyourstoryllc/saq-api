class MessagesController < ApplicationController
  def create
    group_ids = split_param(:group_ids)
    one_to_one_ids = split_param(:one_to_one_ids)
    messages = []

    # Create a message for each group
    valid_group_ids = group_ids & current_user.group_ids.members
    groups = Group.where(id: valid_group_ids) if valid_group_ids.present?

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

        messages << message
      end
    end

    # Create a message for each 1-1
    one_to_one_ids.each do |one_to_one_id|
      one_to_one = load_one_to_one(one_to_one_id)
      next if one_to_one.nil?

      message = Message.new(message_params.merge(one_to_one_id: one_to_one.id))

      if message.save
        unless params[:skip_publish]
          data = MessageSerializer.new(message).as_json
          users = [current_user, one_to_one.other_user(current_user)]

          users.each do |user|
            faye_publisher.publish_one_to_one_message(user, data)
          end
        end

        # Potentially notify the other user, according to his status and preferences
        recipient = one_to_one.other_user(current_user)
        recipient.send_notifications(message)

        messages << message
      end
    end

    render_json messages
  end


  private

  def message_params
    params.permit(:text, :attachment_file, :client_metadata).merge(user_id: current_user.id)
  end

  def load_one_to_one(one_to_one_id)
    one_to_one = OneToOne.new(id: one_to_one_id)

    if one_to_one.attrs.blank?
      one_to_one if one_to_one.save
    else
      one_to_one if one_to_one.authorized?(current_user)
    end
  end
end
