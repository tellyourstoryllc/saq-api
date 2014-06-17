class MessageMailer < BaseMailer
  def all(message, recipient, data)
    data = data.with_indifferent_access

    @recipient = recipient
    @message = message
    @user = @message.user
    @group = @message.group
    if @message.conversation.is_a?(Group)
      @url = Rails.configuration.app['web']['url'] + "/view/#{@group.id}?invite_channel=email"
    else
      id = OneToOne.id_for_user_ids(@user.id, @recipient.id)
      @url = Rails.configuration.app['web']['url'] + "/chat/#{id}?invite_channel=email"
    end

    @media_description = data[:media_description]

    subject = if @media_description.present?
                "#{@user.name} sent #{@media_description}"
              elsif @message.text
                "#{@user.name}: #{@message.text}"
              else
                "#{@user.name} just sent you a message"
              end

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end

  def forwarded_message(message, actor)
    @message = message
    @actor = actor
    @user = @message.user
    @message_description = @message.message_attachment.try(:media_type_name) || 'message'

    id = @message.conversation.id
    @url = Rails.configuration.app['web']['url'] + "/chat/#{id}?invite_channel=email"

    subject = "#{@actor.username} forwarded your #{@message_description}"

    mail(to: @user.emails.map(&:email), subject: subject)
  end

  def liked_message(message, actor)
    @message = message
    @actor = actor
    @user = @message.user

    if @message.story?
      @message_description = 'story'
      @url = Rails.configuration.app['web']['url'] + "?invite_channel=email"
    else
      @message_description = @message.message_attachment.try(:media_type_name) || 'message'
      id = @message.conversation.id
      @url = Rails.configuration.app['web']['url'] + "/chat/#{id}?invite_channel=email"
    end

    subject = "#{@actor.username} liked your #{@message_description}"

    mail(to: @user.emails.map(&:email), subject: subject)
  end

  def new_story(story, recipient)
    @story = story
    @user = @story.user
    @recipient = recipient

    @url = Rails.configuration.app['web']['url'] + "?invite_channel=email"
    subject = "Your friend has posted a story"

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end
end
