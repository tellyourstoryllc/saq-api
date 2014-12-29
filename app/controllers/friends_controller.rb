class FriendsController < ApplicationController
  def index
    outgoing_friend_ids = current_user.paginated_friend_ids(pagination_params)
    incoming_friend_ids = current_user.paginated_pending_incoming_friend_ids(pagination_params)
    mutual_friend_ids = current_user.paginated_mutual_friend_ids(pagination_params)

    friend_lists = {
      object_type: 'friend_lists',
      outgoing_friend_ids: outgoing_friend_ids,
      incoming_friend_ids: incoming_friend_ids,
      mutual_friend_ids: mutual_friend_ids
    }

    user_ids = outgoing_friend_ids | incoming_friend_ids | mutual_friend_ids
    users = user_ids.empty? ? [] : User.includes(:account, :avatar_image, :avatar_video, :emails, :phones).where(id: user_ids)

    render_json [friend_lists, *users.map{ |u| UserWithEmailsAndPhonesSerializer.new(u, scope: current_user).as_json }]
  end

  def add
    usernames = split_param(:usernames)
    friend_codes = split_param(:friend_codes)
    added_users = []

    users = []
    users += User.includes(:account).where(username: usernames) if usernames.present?
    users += User.includes(:account).where(friend_code: friend_codes) if friend_codes.present?

    users.each do |user|
      next unless user.account.registered?

      added_users << user

      if current_user.add_friend(user)
        user.send_new_friend_notifications(current_user)
      end
    end

    render_json added_users, each_serializer: UserWithEmailsAndPhonesSerializer
  end

  def remove
    usernames = split_param(:usernames)
    friend_codes = split_param(:friend_codes)

    users = []
    users += User.where(username: usernames) if usernames.present?
    users += User.where(friend_code: friend_codes) if friend_codes.present?

    current_user.remove_friends(users)

    render_json users, each_serializer: UserWithEmailsAndPhonesSerializer
  end
end
