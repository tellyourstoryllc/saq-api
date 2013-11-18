require "test_helper"

describe OneToOneMessagesController do
  describe "POST /one_to_ones/:id/messages/create" do
    it "must not create a message if the users are not contacts" do
      member = FactoryGirl.create(:user)

      text = 'hey'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1
      one_to_one_id = "#{member.id}-#{current_user.id}"

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {one_to_one_id: one_to_one_id, text: text, token: current_user.token}

        result.must_equal('error' => {'message' => 'Sorry, that could not be found.'})

        one_to_one = OneToOne.new(id: one_to_one_id)
        one_to_one.attrs.must_be_empty
        one_to_one.message_ids.must_be_empty

        current_user.one_to_one_ids.members.must_be_empty
        current_user.one_to_one_user_ids.members.must_be_empty

        member.one_to_one_ids.members.must_be_empty
        member.one_to_one_user_ids.members.must_be_empty
      end
    end

    it "must create a message for an existing one-to-one" do
      member = FactoryGirl.create(:user)
      FactoryGirl.create(:account, user_id: member.id)

      # Make the users contacts
      group = FactoryGirl.create(:group)
      group.add_member(current_user)
      group.add_member(member)

      one_to_one = OneToOne.new(sender_id: current_user.id, recipient_id: member.id)
      one_to_one.save

      text = 'hey'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {one_to_one_id: one_to_one.id, text: text, token: current_user.token}

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => nil, 'one_to_one_id' => one_to_one.id,
                          'user_id' => current_user.id, 'text' => text,
                          'mentioned_user_ids' => [], 'image_url' => nil,
                          'image_thumb_url' => nil, 'client_metadata' => nil,
                          'likes_count' => 0, 'created_at' => now.to_i}])

        one_to_one.message_ids.last.to_i.must_equal message_id

        current_user.one_to_one_ids.members.must_include one_to_one.id
        current_user.one_to_one_user_ids.members.must_include member.id.to_s

        member.one_to_one_ids.members.must_include one_to_one.id
        member.one_to_one_user_ids.members.must_include current_user.id.to_s
      end
    end

    it "must create a message for an non-existant one-to-one" do
      member = FactoryGirl.create(:user)
      FactoryGirl.create(:account, user_id: member.id)

      # Make the users contacts
      group = FactoryGirl.create(:group)
      group.add_member(current_user)
      group.add_member(member)

      text = 'hey'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1
      one_to_one_id = "#{member.id}-#{current_user.id}"

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {one_to_one_id: one_to_one_id, text: text, token: current_user.token}

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => nil, 'one_to_one_id' => one_to_one_id,
                          'user_id' => current_user.id, 'text' => text,
                          'mentioned_user_ids' => [], 'image_url' => nil,
                          'image_thumb_url' => nil, 'client_metadata' => nil,
                          'likes_count' => 0, 'created_at' => now.to_i}])

        one_to_one = OneToOne.new(sender_id: current_user.id, recipient_id: member.id)
        one_to_one.attrs.wont_be_empty
        one_to_one.message_ids.last.to_i.must_equal message_id

        current_user.one_to_one_ids.members.must_include one_to_one.id
        current_user.one_to_one_user_ids.members.must_include member.id.to_s

        member.one_to_one_ids.members.must_include one_to_one.id
        member.one_to_one_user_ids.members.must_include current_user.id.to_s
      end
    end
  end
end
