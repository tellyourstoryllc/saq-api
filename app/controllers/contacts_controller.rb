class ContactsController < ApplicationController
  def index
    render_json current_user.paginated_contacts(pagination_params), each_serializer: UserWithEmailsAndPhonesSerializer
  end

  def add
    user_ids = split_param(:user_ids)
    emails = split_param(:emails)
    phone_numbers = split_param(:phone_numbers).map{ |n| Phone.normalize(n) }
    phone_usernames = split_param(:phone_usernames)

    contact_inviter = ContactInviter.new(current_user)
    invited_users = contact_inviter.add_users(user_ids)
    invited_emails = contact_inviter.add_by_emails(emails, {skip_sending: params[:omit_email_invite], source: params[:source]})
    invited_phone_users = contact_inviter.add_by_phone_numbers(phone_numbers, phone_usernames, {skip_sending: params[:omit_sms_invite], source: params[:source]})

    users = invited_users | invited_phone_users | invited_emails.map(&:user)

    track_sc_users(users, phone_numbers)
    track_initial_sc_import(invited_phone_users)

    render_json users, each_serializer: UserWithEmailsAndPhonesSerializer
  end

  def remove
    user_ids = split_param(:user_ids)
    ContactInviter.new(current_user).remove_users(user_ids)

    render_json User.where(id: user_ids)
  end

  def autoconnect
    hashed_emails = split_param(:hashed_emails)
    hashed_phone_numbers = split_param(:hashed_phone_numbers)

    added_users = ContactInviter.new(current_user).autoconnect(hashed_emails, hashed_phone_numbers)

    user_ids = added_users.map(&:id)
    current_user.matching_phone_contact_user_ids << user_ids if user_ids.present?

    mixpanel.shared_contacts

    render_json added_users, each_serializer: UserWithEmailsAndPhonesSerializer
  end


  private

  def pagination_params
    params.permit(:limit, :offset)
  end

  def track_sc_users(users, phone_numbers)
    return unless params[:sc_users] == 'true'

    user_ids = users.map(&:id)
    current_user.snapchat_friend_ids << user_ids if user_ids.present?
    current_user.snapchat_friend_phone_numbers << phone_numbers if phone_numbers.present?

    current_user.add_to_user_ids_who_friended_me(user_ids)

    snap_invite = params[:sent_snap_invites] == 'true'
    users.each do |recipient|
      mp = MixpanelClient.new(recipient)

      sms_invite = params[:omit_sms_invite] != 'true' && recipient.phones.where(number: phone_numbers).exists? && !recipient.account.registered?
      invite_channel = if snap_invite && sms_invite
                         'snap_and_sms'
                       elsif snap_invite
                         'snap'
                       elsif sms_invite
                         'sms'
                       end

      unless invite_channel.nil?
        recipient.last_invite_at = Time.current.to_i
        mp.received_snap_invite(invite_channel: invite_channel)
      end
    end
  end

  def track_initial_sc_import(invited_phone_users)
    return unless params[:initial_sc_import] == 'true'

    unless current_user.set_initial_snapchat_friend_ids_in_app.exists?
      user_ids_in_app = Account.where(user_id: invited_phone_users.map(&:id)).registered.pluck(:user_id)
      current_user.redis.multi do
        current_user.initial_snapchat_friend_ids_in_app << user_ids_in_app if user_ids_in_app.present?
        current_user.set_initial_snapchat_friend_ids_in_app = 1
      end
    end

    mixpanel.imported_snapchat_friends
    mixpanel.invited_snapchat_friends({}, {delay: 5.seconds}) if params[:sent_snap_invites] == 'true' || params[:omit_sms_invite] != 'true'
  end
end
