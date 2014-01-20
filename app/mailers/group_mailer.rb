class GroupMailer < BaseMailer
  def new_member(recipient, new_member, group)
    @recipient = recipient
    @new_member = new_member
    @group = group

    mail(to: @recipient.emails.map(&:email), subject: "#{@new_member.name} just joined the room \"#{group.name}\"")
  end
end
