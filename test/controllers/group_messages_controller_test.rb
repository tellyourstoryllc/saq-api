require "test_helper"

describe GroupMessagesController do
  describe "POST /messages/create" do
    it "must not create a message if the user is not a member of the group" do
      group = FactoryGirl.create(:group)
      post :create, {group_id: group.id, text: 'hey everyone', token: current_user.token}
      result.must_equal('error' => {'message' => 'Sorry, that could not be found.'})
    end

    it "must create a message" do
      FactoryGirl.create(:account, user_id: current_user.id)

      group = FactoryGirl.create(:group)
      group.add_member(current_user)
      text = 'hey everyone'

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, token: current_user.token}
        message_id = group.message_ids.last

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'one_to_one_id' => nil, 'user_id' => current_user.id, 'rank' => 0,
                          'text' => text, 'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil,
                          'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
                          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}])
      end
    end

    it "must create a message with one mention" do
      FactoryGirl.create(:account, user_id: current_user.id)

      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      user = FactoryGirl.create(:user)
      FactoryGirl.create(:account, user_id: user.id)
      group.add_member(user)

      text = 'hey everyone'

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: user.id, token: current_user.token}
        message_id = group.message_ids.last

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'one_to_one_id' => nil, 'user_id' => current_user.id, 'rank' => 0,
                          'text' => text, 'mentioned_user_ids' => [user.id], 'attachment_url' => nil, 'attachment_content_type' => nil,
                          'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
                          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}])
      end
    end

    it "must create a message with multiple mentions" do
      FactoryGirl.create(:account, user_id: current_user.id)

      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      u1 = FactoryGirl.create(:user)
      FactoryGirl.create(:account, user_id: u1.id)
      group.add_member(u1)

      u2 = FactoryGirl.create(:user)
      FactoryGirl.create(:account, user_id: u2.id)
      group.add_member(u2)

      text = 'hey everyone'

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: [u1.id, u2.id].join(','), token: current_user.token}
        message_id = group.message_ids.last

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'one_to_one_id' => nil, 'user_id' => current_user.id, 'rank' => 0,
                          'text' => text, 'mentioned_user_ids' => [u1.id, u2.id], 'attachment_url' => nil, 'attachment_content_type' => nil,
                          'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
                          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}])
      end
    end

    it "must create a message and sanitize mentions" do
      FactoryGirl.create(:account, user_id: current_user.id)

      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      u1 = FactoryGirl.create(:user)
      FactoryGirl.create(:account, user_id: u1.id)
      group.add_member(u1)

      text = 'hey everyone'

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: [99999, u1.id].join(','), token: current_user.token}
        message_id = group.message_ids.last

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'one_to_one_id' => nil, 'user_id' => current_user.id, 'rank' => 0,
                          'text' => text, 'mentioned_user_ids' => [u1.id], 'attachment_url' => nil, 'attachment_content_type' => nil,
                          'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
                          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}])
      end
    end

    it "must create a message and allow an @all mention" do
      FactoryGirl.create(:account, user_id: current_user.id)

      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      text = 'hey everyone'

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: '-1', token: current_user.token}
        message_id = group.message_ids.last

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'one_to_one_id' => nil, 'user_id' => current_user.id, 'rank' => 0,
                          'text' => text, 'mentioned_user_ids' => ['-1'], 'attachment_url' => nil, 'attachment_content_type' => nil,
                          'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
                          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}])
      end
    end
  end


  describe "GET /groups/:group_id/messages" do
    it "must return the most recent page of messages" do
      Group.stub :page_size, 2 do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

        group.add_member(current_user)
        group.add_member(member)

        m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
        m1.save

        m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
        m2.save

        m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hi again')
        m3.save

        get :index, {group_id: group.id, token: current_user.token}

        result.must_equal [
          {
            'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id, 'one_to_one_id' => nil,
            'user_id' => current_user.id, 'rank' => 1, 'text' => 'oh hai', 'mentioned_user_ids' => [],
            'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
            'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m2.created_at
          },
          {
            'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id, 'one_to_one_id' => nil,
            'user_id' => member.id, 'rank' => 2, 'text' => 'hi again', 'mentioned_user_ids' => [],
            'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
            'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m3.created_at
          }
        ]
      end
    end

    it "must return the most recent page of messages with a given limit" do
      Group.stub :page_size, 2 do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

        group.add_member(current_user)
        group.add_member(member)

        m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
        m1.save

        m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
        m2.save

        m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hi again')
        m3.save

        get :index, {group_id: group.id, limit: 3, token: current_user.token}

        result.must_equal [
          {
            'object_type' => 'message', 'id' => m1.id, 'group_id' => group.id, 'one_to_one_id' => nil,
            'user_id' => member.id, 'rank' => 0, 'text' => 'hey guys', 'mentioned_user_ids' => [],
            'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
            'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m1.created_at
          },
          {
            'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id, 'one_to_one_id' => nil,
            'user_id' => current_user.id, 'rank' => 1, 'text' => 'oh hai', 'mentioned_user_ids' => [],
            'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
            'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m2.created_at
          },
          {
            'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id, 'one_to_one_id' => nil,
            'user_id' => member.id, 'rank' => 2, 'text' => 'hi again', 'mentioned_user_ids' => [],
            'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
            'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m3.created_at
          }
        ]
      end
    end

    it "must return the most recent page of messages, starting from a given message id" do
      Group.stub :page_size, 2 do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

        group.add_member(current_user)
        group.add_member(member)

        m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
        m1.save

        m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
        m2.save

        m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hi again')
        m3.save

        m4 = Message.new(group_id: group.id, user_id: member.id, text: 'hello?')
        m4.save

        get :index, {group_id: group.id, below_rank: 3, token: current_user.token}

        result.must_equal [
          {
            'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id, 'one_to_one_id' => nil,
            'user_id' => current_user.id, 'rank' => 1, 'text' => 'oh hai', 'mentioned_user_ids' => [],
            'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
            'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m2.created_at
          },
          {
            'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id, 'one_to_one_id' => nil,
            'user_id' => member.id, 'rank' => 2, 'text' => 'hi again', 'mentioned_user_ids' => [],
            'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
            'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m3.created_at
          }
        ]
      end
    end
  end
end
