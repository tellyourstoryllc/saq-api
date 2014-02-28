class UserMerger
  attr_accessor :old_user, :new_user

  def initialize(old_user, new_user)
    self.old_user = old_user
    self.new_user = new_user
  end

  def faye_publisher
    @faye_publisher ||= FayePublisher.new(new_user.token)
  end

  def old_faye_publisher
    @old_faye_publisher ||= FayePublisher.new(old_user.token)
  end

  def self.merge(old_user, new_user)
    new(old_user, new_user).merge
  end

  # Merge old_user into new_user
  def merge
    return if old_user.nil? || new_user.nil?

    copy_missing_one_to_ones
    replace_old_with_new_in_groups
    set_replacement_references
    deactivate_old_user
    faye_publisher.broadcast_to_contacts
    old_faye_publisher.broadcast_to_contacts
  end

  # Copy all 1-1s (and their messages) from the old user to the
  # new user that the new user isn't alredy in
  def copy_missing_one_to_ones
    old_user.one_to_ones.each do |one_to_one|
      other_user = one_to_one.other_user(old_user)
      Rails.logger.debug "Attempting to copy 1-1 for user #{other_user.id} ..."

      unless new_user.one_to_one_user_ids.include?(other_user.id)
        Rails.logger.debug "Copying 1-1 for user #{other_user.id} ..."

        o = OneToOne.new(sender_id: other_user.id, recipient_id: new_user.id)
        o.save

        if o.attrs.exists?
          messages = Message.pipelined_find(one_to_one.message_ids.members)
          messages.each do |m|
            user_id = m.user_id == other_user.id ? m.user_id : new_user.id
            new_message = Message.new(one_to_one_id: o.id, user_id: user_id,
                                      text: m.text, mentioned_user_ids: m.mentioned_user_ids.join(','))
            attachment_url = m.message_attachment.attachment.url if m.message_attachment
            new_message.attachment_url = attachment_url if attachment_url

            if new_message.save
              data = MessageSerializer.new(new_message).as_json

              [new_user, other_user].each do |oo_user|
                faye_publisher.publish_one_to_one_message(oo_user, data)
              end
            end
          end
        end
      else
        Rails.logger.debug "Skipped copying 1-1 for user #{other_user.id}"
      end
    end
  end

  # Add new user to groups old user was in, and remove
  # old user from all his groups
  def replace_old_with_new_in_groups
    old_user.groups.each do |group|
      # Add new user to group if needed
      if !group.member?(new_user) && !group.banned?(new_user)
        group.redis.multi do
          group.member_ids << new_user.id
          new_user.group_ids << group.id
          new_user.group_join_times[group.id] = Time.current.to_i
        end

        # Make new user an admin if needed
        group.admin_ids << new_user.id if group.admin?(old_user)
      end

      # Remove old user from group and admin if needed
      group.redis.multi do
        group.admin_ids.delete(old_user.id)
        group.member_ids.delete(old_user.id)
        old_user.group_ids.delete(group.id)
      end

      # Publish group once after all changes
      faye_publisher.publish_to_group(group, PublishGroupSerializer.new(group).as_json)

      group_data = GroupSerializer.new(group).as_json
      faye_publisher.publish_group_to_user(new_user, group_data)
      faye_publisher.publish_group_to_user(old_user, group_data)
    end
  end

  def set_replacement_references
    User.redis.multi do
      new_user.replaced_user_ids[old_user.id] = Time.current.to_i
      old_user.replaced_by_user_id = new_user.id
    end
  end

  def deactivate_old_user
    old_user.deactivate!
  end
end
