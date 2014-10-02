class MessagesController < ApplicationController
  before_action :load_message, only: :export
  before_action :load_my_message, only: :delete


  def create
    @stories = []
    @messages = []

    create_group_messages
    create_one_to_one_messages
    create_story
    send_forward_messages

    render_json @stories + @messages
  end

  def export
    @message.record_export(current_user, params[:method])

    # Send export meta messages to the most recent and original users
    @message.send_export_meta_messages(current_user, params[:method])

    render_success
  end

  def delete
    @message.delete(current_user)
    load_my_message
    render_json @message
  end


  private

  def message_params
    params.permit(:text, :attachment_file, :attachment_metadata, :client_metadata,
                  :received, :original_message_id, :forward_message_id, :created_at).merge(user_id: current_user.id)
  end

  def story_params
    message_params.merge(user_id: params[:story_creator_id], snapchat_media_id: params[:snapchat_media_id])
  end

  # Create a message for each group
  def create_group_messages
    group_ids = split_param(:group_ids)
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
        unless importing_from_sc
          group_mixpanel.sent_daily_message(group)
          mixpanel.daily_message_events(message)
        end

        @messages << message
      end
    end
  end

  # Create a message for each 1-1
  def create_one_to_one_messages
    one_to_one_ids = split_param(:one_to_one_ids)

    one_to_one_ids.each do |one_to_one_id|
      one_to_one = load_one_to_one(one_to_one_id)
      next if one_to_one.nil?

      message = Message.new(message_params.merge(one_to_one_id: one_to_one.id))

      if message.save
        mark_as_seen(one_to_one, message) if message.user_id == current_user.id

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
        mixpanel.daily_message_events(message) unless importing_from_sc

        Robot.reply_to(current_user, message)

        @messages << message
      end
    end
  end

  # Create a story
  def create_story
    return unless Bool.parse(params[:create_story]) &&
      params[:snapchat_media_id].present? && params[:story_creator_id].present?

    stories_list = load_stories_list(params[:story_creator_id])
    return if stories_list.nil?

    story = Story.find_or_create(story_params.merge(stories_list_id: stories_list.id))

    if story
      # Push the story to the relevant users' stories lists and feeds
      pushed_user_ids = story.push_to_feeds(current_user)

      # Notify the users to whose feed this story was just added
      User.where(id: pushed_user_ids).find_each do |user|
        user.send_story_notifications(story)
      end

      # Track activity in Mixpanel
      mixpanel.daily_message_events(story) unless importing_from_sc

      @stories << story
    end
  end

  # Send forward meta messages to the most recent and original users
  def send_forward_messages
    if @messages.present? && @messages.first.forward_message
      @messages.first.send_forward_meta_messages
    end
  end

  def load_one_to_one(one_to_one_id)
    one_to_one = OneToOne.new(id: one_to_one_id)

    if one_to_one.attrs.blank?
      one_to_one if one_to_one.save
    else
      one_to_one if one_to_one.authorized?(current_user)
    end
  end

  def load_stories_list(story_creator_id)
    stories_list = StoriesList.new(creator_id: story_creator_id, viewer_id: current_user.id)

    if stories_list.attrs.blank?
      stories_list if stories_list.save
    else
      stories_list if stories_list.authorized?(current_user)
    end
  end

  def send_invites(message, other_user)
    other_user.emails.each do |email|
      Invite.create!(sender_id: current_user.id, recipient: other_user, invited_email: email.email,
                     new_user: false, can_log_in: other_user.account.can_log_in?, message: message,
                     skip_sending: params[:omit_email_invite])
    end

    other_user.phones.each do |phone|
      Invite.create!(sender_id: current_user.id, recipient: other_user, invited_phone: phone.number,
                     new_user: false, can_log_in: other_user.account.can_log_in?, message: message,
                     skip_sending: !send_sms_invites?)
    end
  end

  def load_message
    @message = Message.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @message.attrs.exists? &&
      @message.conversation && @message.conversation.fetched_member_ids.include?(current_user.id)
  end

  def load_my_message
    @message = Message.new(id: params[:id])
    raise Peanut::Redis::RecordNotFound unless @message.attrs.exists? &&
      @message.user_id == current_user.id
  end

  def mark_as_seen(one_to_one, message)
    one_to_one.viewer = current_user
    one_to_one.last_seen_rank = message.rank
  end
end
