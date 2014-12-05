class FriendsController < ApplicationController
  def index
    outgoing_friend_ids = current_user.paginated_snapchat_friend_ids(pagination_params)
    incoming_friend_ids = current_user.paginated_pending_incoming_friend_ids(pagination_params)
    mutual_friend_ids = current_user.paginated_mutual_friend_ids(pagination_params)

    friend_lists = {
      object_type: 'friend_lists',
      outgoing_friend_ids: outgoing_friend_ids,
      incoming_friend_ids: incoming_friend_ids,
      mutual_friend_ids: mutual_friend_ids
    }

    user_ids = outgoing_friend_ids | incoming_friend_ids | mutual_friend_ids
    users = User.includes(:account, :avatar_image, :avatar_video, :emails, :phones).where(id: user_ids)

    render_json [friend_lists, *users.map{ |u| UserWithEmailsAndPhonesSerializer.new(u).as_json }]
  end

  def add
    usernames = split_param(:usernames)
    added_users = []

    users = User.includes(:account).where(username: usernames)
    users.each do |user|
      next unless user.account.registered?

      added_users << user
      current_user.add_friend(user)
    end

    render_json added_users, each_serializer: UserWithEmailsAndPhonesSerializer
  end

  def remove
    usernames = split_param(:usernames)
    users = User.where(username: usernames)
    current_user.remove_friends(users)

    render_json users, each_serializer: UserWithEmailsAndPhonesSerializer
  end
end
