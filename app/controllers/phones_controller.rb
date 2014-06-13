class PhonesController < ApplicationController
  def create
    number = Phone.normalize(params[:phone_number])
    render_error and return if number.blank?

    @phone = Phone.find_or_initialize_by(number: number)

    if @phone.persisted?
      send_verification if @phone.user_id == current_user.id
    else
      @phone.user = current_user
      @phone.save!

      send_verification
    end

    render_json current_user
  end

  def verify
    number = Phone.normalize(params[:phone_number])
    render_error and return if number.blank?

    @phone = Phone.find_by(number: number)
    render_error and return if @phone.nil?

    if @phone.verify_by_code!(current_user, params[:phone_verification_code], {notify_friends: true})
      mixpanel.verified_phone(@phone, :entered_phone)
      render_json current_user
    else
      render_error
    end
  end

  def add
    phone_numbers = split_param(:phone_numbers).map{ |n| Phone.normalize(n) }
    phone_usernames = split_param(:phone_usernames)

    contact_inviter = ContactInviter.new(current_user)
    users = contact_inviter.add_by_phone_numbers(phone_numbers, phone_usernames, {skip_sending: !send_sms_invites?, source: params[:source]})

    track_sc_users(users, phone_numbers)
    track_initial_sc_import

    render_json users, each_serializer: UserWithEmailsAndPhonesSerializer
  end


  private

  def send_verification
    HookClient.send_verification(@phone.number, @phone.verification_code) unless @phone.verified?
  end

  def track_sc_users(users, phone_numbers)
    user_ids = users.map(&:id)
    return if user_ids.blank?

    current_user.snapchat_friend_ids << user_ids

    phone_numbers = phone_numbers.delete_if(&:blank?)
    current_user.snapchat_friend_phone_numbers << phone_numbers if phone_numbers.present?

    # TODO need to decide who to notify
    # current_user.add_to_user_ids_who_friended_me(user_ids)

    snap_invite = sent_snap_invites?
    users.each do |recipient|
      next if recipient.account.registered?

      sms_invite = send_sms_invites? && (phone = recipient.phones.find_by(number: phone_numbers))
      invite_channel = if snap_invite && sms_invite
                         'snap_and_sms'
                       elsif snap_invite
                         'snap'
                       elsif sms_invite
                         'sms'
                       end

      unless invite_channel.nil?
        recipient.last_invite_at = Time.current.to_i

        mp = MixpanelClient.new(recipient)
        mp.received_snap_invite(sender: current_user, invite_channel: invite_channel,
                                snap_invite_ad: current_user.snap_invite_ad, recipient_phone: phone)
      end
    end
  end

  def track_initial_sc_import
    return unless params[:initial_sc_import] == 'true'

    unless current_user.set_initial_snapchat_friend_ids_in_app.exists?
      user_ids_in_app = current_user.snapchat_friend_ids_in_app
      current_user.redis.multi do
        current_user.initial_snapchat_friend_ids_in_app << user_ids_in_app if user_ids_in_app.present?
        current_user.set_initial_snapchat_friend_ids_in_app = 1
      end
    end

    mixpanel.imported_snapchat_friends
    mixpanel.invited_snapchat_friends({}, {delay: 5.seconds}) if sent_snap_invites? || send_sms_invites?
  end
end
