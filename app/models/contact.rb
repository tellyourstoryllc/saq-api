class Contact
  def self.add_users(current_user, user_ids)
    User.where(id: user_ids.map(&:to_s)).find_each do |user|
      add_with_reciprocal(current_user, user)
    end
  end

  def self.remove_users(current_user, user_ids)
    User.where(id: user_ids.map(&:to_s)).find_each do |user|
      remove_user(current_user, user)
    end
  end

  def self.add_with_reciprocal(user, other_user)
    return if User.blocked?(user, other_user)

    User.redis.multi do
      add_user(user, other_user)
      add_user(other_user, user)
    end
  end

  def self.add_user(user, other_user)
    User.redis.multi do
      user.contact_ids << other_user.id
      other_user.reciprocal_contact_ids << user.id
    end
  end

  def self.remove_user(user, other_user)
    User.redis.multi do
      user.contact_ids.delete(other_user.id)
      other_user.reciprocal_contact_ids.delete(user.id)
    end
  end
end
