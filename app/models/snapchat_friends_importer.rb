class SnapchatFriendsImporter
  FRIEND_TYPES = {0 => :confirmed, 1 => :unconfirmed, 2 => :blocked, 3 => :deleted}
  attr_accessor :current_user


  def initialize(current_user)
    self.current_user = current_user
  end

  def import(outgoing_usernames, outgoing_types, incoming_usernames, incoming_types)
    imported_users = {outgoing: [], incoming: []}
    imported_users[:outgoing] += import_usernames(outgoing_usernames, outgoing_types, :outgoing)
    imported_users[:incoming] += import_usernames(incoming_usernames, incoming_types, :incoming)
    imported_users
  end

  def import_usernames(usernames, types, direction)
    imported_users = []
    return imported_users unless usernames.size == types.size

    users = User.where(username: usernames)

    usernames.each_with_index do |username, i|
      user = users.detect{ |u| u.username.downcase == username.downcase }
      user = create_missing_user(username, user)
      next if user.nil?

      friend_type = FRIEND_TYPES[types[i].to_i] unless types[i].blank?

      imported_user = case friend_type
                      when :confirmed, :unconfirmed
                        add_friend(user, direction)
                      when :blocked
                        block_user(user)
                      when :deleted
                        defriend(user)
                      end

      imported_users << imported_user if imported_user
    end

    imported_users
  end

  def create_missing_user(username, user)
    account = user.try(:account)

    # If the user doesn't exist, create one
    unless account
      account = Account.create(user_attributes: {username: username})
      user = account.user if account.persisted?
    end

    user
  end

  def add_friend(user, direction)
    raise ArgumentError unless [:outgoing, :incoming].include?(direction)

    adder, addee = case direction
                   when :outgoing then [current_user, user]
                   when :incoming then [user, current_user]
                   end

    User.redis.multi do
      adder.snapchat_friend_ids << addee.id
      addee.snapchat_follower_ids << adder.id
    end

    user
  end

  def block_user(user)
    current_user.block(user)
  end

  def defriend(user)
    User.redis.multi do
      current_user.snapchat_friend_ids.delete(user.id)
      user.snapchat_follower_ids.delete(current_user.id)

      user.snapchat_friend_ids.delete(current_user.id)
      current_user.snapchat_follower_ids.delete(user.id)
    end

    user
  end
end
