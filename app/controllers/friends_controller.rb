class FriendsController < ApplicationController
  def import
    outgoing_usernames = split_param(:outgoing_usernames)
    outgoing_types = split_param(:outgoing_types)

    incoming_usernames = split_param(:incoming_usernames)
    incoming_types = split_param(:incoming_types)

    users_hash = SnapchatFriendsImporter.new(current_user).import(outgoing_usernames, outgoing_types, incoming_usernames, incoming_types)

    track_sc_users(users_hash[:outgoing])
    track_initial_sc_import

    render_json users_hash.values.flatten, each_serializer: UserWithEmailsAndPhonesSerializer
  end
end
