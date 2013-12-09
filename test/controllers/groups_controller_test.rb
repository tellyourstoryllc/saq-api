require "test_helper"

describe GroupsController do
  describe "POST /groups/create" do
    describe "invalid" do
      it "must not create a group if it's invalid" do
        post :create, {token: current_user.token}
        result.must_equal('error' => {'message' => "Validation failed: Name can't be blank"})
      end
    end


    describe "valid" do
      it "must create a group" do
        post :create, {name: 'Cool Dudes', token: current_user.token}

        group = Group.last
        result.must_equal [{'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil, 'avatar_url' => nil,
          'wallpaper_url' => nil, 'admin_ids' => [current_user.id], 'member_ids' => [current_user.id],
          'last_message_at' => nil}]
      end
    end
  end


  describe "POST /groups/:id/update" do
    it "must not update a group if the user is not a member of the group" do
      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user)

      group.add_admin(member)
      group.add_member(member)

      post :update, {id: group.id, topic: 'new topic', token: current_user.token}

      result.must_equal('error' => {'message' => 'Sorry, that could not be found.'})
    end

    it "must update a group's topic if the user is a member" do
      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user)

      group.add_admin(member)
      group.add_member(member)
      group.add_member(current_user)

      post :update, {id: group.id, topic: 'new topic', token: current_user.token}

      result.must_equal [{'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
        'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => 'new topic', 'avatar_url' => nil,
        'wallpaper_url' => nil, 'admin_ids' => [member.id], 'member_ids' => [member.id, current_user.id].sort,
        'last_message_at' => nil}]
    end

    it "must not update a group's name if the user is not an admin of the group" do
      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user)

      group.add_admin(member)
      group.add_member(member)
      group.add_member(current_user)

      post :update, {id: group.id, name: 'Really Cool Dudes', token: current_user.token}

      result.must_equal [{'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
        'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil, 'avatar_url' => nil,
        'wallpaper_url' => nil, 'admin_ids' => [member.id], 'member_ids' => [member.id, current_user.id].sort,
        'last_message_at' => nil}]
    end

    it "must update a group's name if the user is an admin of the group" do
      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user)

      group.add_admin(member)
      group.add_admin(current_user)
      group.add_member(member)
      group.add_member(current_user)

      post :update, {id: group.id, name: 'Really Cool Dudes', token: current_user.token}

      result.must_equal [{'object_type' => 'group', 'id' => group.id, 'name' => 'Really Cool Dudes',
        'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil, 'avatar_url' => nil, 'wallpaper_url' => nil,
        'admin_ids' => [member.id, current_user.id].sort, 'member_ids' => [member.id, current_user.id].sort,
        'last_message_at' => nil}]
    end
  end


  describe "POST /groups/join/:join_code" do
    it "must not join the group if the join code is not valid" do
      group = FactoryGirl.create(:group)
      post :join, {join_code: 'invalid', token: current_user.token}
      result.must_equal('error' => {'message' => 'Sorry, that could not be found.'})
    end

    it "must join the group and return the group, its users, and its most recent page of messages" do
      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

      group.add_admin(member)
      group.add_member(member)

      message = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
      message.save

      post :join, {join_code: group.join_code, token: current_user.token}

      result.size.must_equal 4

      result.must_include({
        'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
        'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil, 'avatar_url' => nil,
        'wallpaper_url' => nil, 'admin_ids' => [member.id], 'member_ids' => [member.id, current_user.id].sort,
        'last_message_at' => group.last_message_at
      })

      result.must_include({
        'object_type' => 'user', 'id' => member.id, 'name' => 'Jane Doe', 'username' => member.username,
        'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => 'around', 'client_type' => nil,
        'avatar_url' => nil
      })

      result.must_include({
        'object_type' => 'user', 'id' => current_user.id, 'name' => 'John Doe', 'username' => current_user.username,
        'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
        'token' => current_user.token, 'client_type' => nil,
        'avatar_url' => nil
      })

      result.must_include({
        'object_type' => 'message', 'id' => message.id, 'group_id' => group.id,
        'one_to_one_id' => nil, 'user_id' => member.id, 'rank' => 0, 'text' => 'hey guys',
        'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
        'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
        'client_metadata' => nil, 'likes_count' => 0, 'created_at' => message.created_at
      })
    end
  end


  describe "POST /groups/:id/leave" do
    it "must leave the group" do
      group = FactoryGirl.create(:group, creator_id: current_user.id)
      member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

      group.add_member(member)

      group.admin_ids.members.must_equal [current_user.id]
      group.member_ids.members.sort.must_equal [current_user.id, member.id].sort
      current_user.group_ids.must_include group.id

      post :leave, {id: group.id, token: current_user.token}

      result.must_equal []

      group.admin_ids.members.must_be_empty
      group.member_ids.members.must_equal [member.id]
      current_user.group_ids.wont_include group.id
    end
  end


  describe "GET /groups/:id" do
    it "must return the group, its users, and its most recent page of messages" do
      Group.stub :page_size, 2 do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

        group.add_admin(current_user)
        group.add_member(current_user)
        group.add_member(member)

        current_user.update!(status: 'away', status_text: 'be back soon')
        FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active', client_type: 'phone')

        m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
        m1.save

        m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
        m2.save

        m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hey!')
        m3.save

        get :show, {id: group.id, token: current_user.token}

        result.size.must_equal 5

        result.must_include({
          'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil, 'avatar_url' => nil,
          'wallpaper_url' => nil, 'admin_ids' => [current_user.id], 'member_ids' => [member.id, current_user.id].sort,
          'last_message_at' => group.last_message_at
        })

        result.must_include({
          'object_type' => 'user', 'id' => member.id, 'name' => 'Jane Doe', 'username' => member.username,
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => 'around', 'client_type' => nil,
          'avatar_url' => nil
        })

        result.must_include({
          'object_type' => 'user', 'id' => current_user.id, 'name' => 'John Doe', 'username' => current_user.username,
          'status' => 'away', 'idle_duration' => nil, 'status_text' => 'be back soon',
          'token' => current_user.token, 'client_type' => 'phone',
          'avatar_url' => nil
        })

        result.must_include({
          'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id,
          'one_to_one_id' => nil, 'user_id' => current_user.id, 'rank' => 1,
          'text' => 'oh hai', 'mentioned_user_ids' => [],
          'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
          'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
          'client_metadata' => nil, 'likes_count' => 0,
          'created_at' => m2.created_at
        })

        result.must_include({
          'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id,
          'one_to_one_id' => nil, 'user_id' => member.id, 'rank' => 2, 'text' => 'hey!',
          'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
          'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m3.created_at
        })
      end
    end

    it "must return the group, its users, and its most recent page of messages with a given limit" do
      Group.stub :page_size, 2 do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

        group.add_admin(current_user)
        group.add_member(current_user)
        group.add_member(member)

        current_user.update!(status: 'away', status_text: 'be back soon')
        FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')

        m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
        m1.save

        m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
        m2.save

        m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hey!')
        m3.save

        get :show, {id: group.id, limit: 3, token: current_user.token}

        result.size.must_equal 6

        result.must_include({
          'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil, 'avatar_url' => nil,
          'wallpaper_url' => nil, 'admin_ids' => [current_user.id], 'member_ids' => [member.id, current_user.id].sort,
          'last_message_at' => group.last_message_at
        })

        result.must_include({
          'object_type' => 'user', 'id' => member.id, 'name' => 'Jane Doe', 'username' => member.username,
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => 'around', 'client_type' => nil,
          'avatar_url' => nil
        })

        result.must_include({
          'object_type' => 'user', 'id' => current_user.id, 'name' => 'John Doe', 'username' => current_user.username,
          'status' => 'away', 'idle_duration' => nil, 'status_text' => 'be back soon',
          'token' => current_user.token, 'client_type' => 'web',
          'avatar_url' => nil
        })

        result.must_include({
          'object_type' => 'message', 'id' => m1.id, 'group_id' => group.id,
          'one_to_one_id' => nil, 'user_id' => member.id, 'rank' => 0, 'text' => 'hey guys',
          'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
          'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m1.created_at
        })

        result.must_include({
          'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id,
          'one_to_one_id' => nil, 'user_id' => current_user.id, 'rank' => 1, 'text' => 'oh hai',
          'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
          'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m2.created_at
        })

        result.must_include({
          'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id,
          'one_to_one_id' => nil, 'user_id' => member.id, 'rank' => 2, 'text' => 'hey!',
          'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil, 'attachment_preview_url' => nil,
          'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => m3.created_at
        })
      end
    end


    describe 'GET /groups/find' do
      it "must return the group by join_code even if the user isn't registered" do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user)

        get :find, {join_code: group.join_code}
        result.must_equal [{
          'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil, 'avatar_url' => nil,
          'wallpaper_url' => nil, 'admin_ids' => [], 'member_ids' => [], 'last_message_at' => nil
        }]
      end
    end
  end
end
