class MessageMailer < BaseMailer
  def mention(message, recipient, status)
    @recipient = recipient
    @status = status
    @message = message
    @user = @message.user
    @group = @message.group
    @mentioned_name = message.mentioned_all? ? '@all' : 'you'

    mail(to: @recipient.emails.map(&:email), subject: "#{@user.name} mentioned #{@mentioned_name} in the room \"#{@group.name}\"")
  end

  def one_to_one(message, recipient, status)
    @recipient = recipient
    @status = status
    @message = message
    @user = @message.user

    mail(to: @recipient.emails.map(&:email), subject: "#{@user.name} sent you a 1-1 message")
  end
end
