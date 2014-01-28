class MessageMailer < BaseMailer
  def mention(message, recipient, status)
    @recipient = recipient
    @status = status
    @message = message
    @user = @message.user
    @group = @message.group
    @mentioned_name = message.mentioned_all? ? '@all' : 'you'
    @url = Rails.configuration.app['web']['url'] + "/rooms/#{@group.id}"

    mail(to: @recipient.emails.map(&:email), subject: "#{@user.name} mentioned #{@mentioned_name} in the room \"#{@group.name}\"")
  end

  def one_to_one(message, recipient, status)
    @recipient = recipient
    @status = status
    @message = message
    @user = @message.user
    id = OneToOne.id_for_user_ids(@user.id, @recipient.id)
    @url = Rails.configuration.app['web']['url'] + "/rooms/#{id}"

    mail(to: @recipient.emails.map(&:email), subject: "#{@user.name} sent you a 1-1 message")
  end

  def all_content(message, recipient, data)
    data = data.with_indifferent_access

    @recipient = recipient
    @message = message
    @user = @message.user
    @group = @message.group
    @url = Rails.configuration.app['web']['url'] + "/rooms/#{@group.id}"
    @media_description = data[:media_description]

    subject = if @media_description.present?
                "#{@user.name} shared #{@media_description} in the room \"#{@group.name}\""
              else
                "#{@user.name} said \"#{@message.text}\" in the room \"#{@group.name}\""
              end

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end

  def all_digest(recipient, data)
    data = data.with_indifferent_access

    @recipient = recipient
    @group_name = data[:group_name]
    @names = data[:names]
    @group = Group.find(data[:group_id]) if data[:group_id]

    if @names && @group
      @url = Rails.configuration.app['web']['url'] + "/rooms/#{@group.id}"

      @group_name = @group.name
      @body = subject = case @names.size
                        when 1 then "#{@names.first} is chatting in the room \"#{@group_name}\""
                        when 2 then "#{@names.first} and #{@names.last} are chatting in the room \"#{@group_name}\""
                        else "#{@names.shift}, #{@names.shift}, and #{@names.size} other#{'s' unless @names.size == 1} are chatting in the room \"#{@group_name}\""
                        end
    else
      @url = Rails.configuration.app['web']['url']
      @users_count = data[:users_count]
      @group_names = data[:group_names]

      subject = "#{@users_count} #{@users_count == 1 ? 'person is' : 'people are'} chatting in #{@group_names.size} room#{'s' unless @group_names.size == 1}: #{@group_names.to_sentence}"
    end

    mail(to: @recipient.emails.map(&:email), subject: subject)
  end
end
