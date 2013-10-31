class MessageMailer < ActionMailer::Base
  default from: "groupchatappthing@example.com"

  def mention(message, recipient, status)
    @recipient = recipient
    @status = status
    @message = message
    @user = @message.user
    @group = @message.group
    @mentioned_name = message.mentioned_all? ? '@all' : 'you'

    mail(to: @recipient.email, subject: "#{@user.name} mentioned #{@mentioned_name} in the room \"#{@group.name}\"")
  end
end