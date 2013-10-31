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
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
          'admin_ids' => [current_user.id], 'member_ids' => [current_user.id]}]
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
        'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => 'new topic',
        'admin_ids' => [member.id], 'member_ids' => [member.id, current_user.id]}]
    end

    it "must not update a group's name if the user is not an admin of the group" do
      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user)

      group.add_admin(member)
      group.add_member(member)
      group.add_member(current_user)

      post :update, {id: group.id, name: 'Really Cool Dudes', token: current_user.token}

      result.must_equal [{'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
        'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
        'admin_ids' => [member.id], 'member_ids' => [member.id, current_user.id]}]
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
        'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
        'admin_ids' => [member.id, current_user.id], 'member_ids' => [member.id, current_user.id]}]
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

      result.must_equal [
        {
          'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
          'admin_ids' => [member.id], 'member_ids' => [member.id, current_user.id]
        },
        {
          'object_type' => 'user', 'id' => member.id, 'name' => 'Jane Doe',
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => 'around'
        },
        {
          'object_type' => 'user', 'id' => current_user.id, 'name' => 'John Doe',
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'token' => current_user.token
        },
        {
          'object_type' => 'message', 'id' => message.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hey guys', 'mentioned_user_ids' => [],
          'image_url' => nil, 'image_thumb_url' => nil, 'likes_count' => 0, 'created_at' => message.created_at
        }
      ]
    end
  end


  describe "GET /groups" do
    it "must return the groups to which the user currently belongs" do
      group = FactoryGirl.create(:group)
      group.add_admin(current_user)
      group.add_member(current_user)

      group2 = FactoryGirl.create(:group, name: 'Another Group')
      group2.add_admin(current_user)
      group2.add_member(current_user)

      get :index, {token: current_user.token}

      result.must_equal [
        {
          'object_type' => 'group', 'id' => group2.id, 'name' => 'Another Group',
          'join_url' => "http://test.host/join/#{group2.join_code}", 'topic' => nil,
          'admin_ids' => [current_user.id], 'member_ids' => [current_user.id]
        },
        {
          'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
          'admin_ids' => [current_user.id], 'member_ids' => [current_user.id]
        }
      ]
    end
  end


  describe "GET /groups/:id" do
    it "must not return the group if the user is not a member" do
      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user)
      group.add_member(member)

      get :show, {id: group.id, token: current_user.token}
      result.must_equal('error' => {'message' => 'Sorry, that could not be found.'})
    end

    it "must return the group, its users, and its most recent page of messages" do
      silence_warnings{ Group::PAGE_SIZE = 2 }

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

      get :show, {id: group.id, token: current_user.token}

      result.must_equal [
        {
          'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
          'admin_ids' => [current_user.id], 'member_ids' => [member.id, current_user.id]
        },
        {
          'object_type' => 'user', 'id' => member.id, 'name' => 'Jane Doe',
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => 'around'
        },
        {
          'object_type' => 'user', 'id' => current_user.id, 'name' => 'John Doe',
          'status' => 'away', 'idle_duration' => nil, 'status_text' => 'be back soon', 'token' => current_user.token
        },
        {
          'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id,
          'user_id' => current_user.id, 'text' => 'oh hai', 'mentioned_user_ids' => [],
          'image_url' => nil, 'image_thumb_url' => nil, 'likes_count' => 0, 'created_at' => m2.created_at
        },
        {
          'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hey!', 'mentioned_user_ids' => [],
          'image_url' => nil, 'image_thumb_url' => nil, 'likes_count' => 0, 'created_at' => m3.created_at
        }
      ]
    end

    it "must return the group, its users, and its most recent page of messages with a given limit" do
      silence_warnings{ Group::PAGE_SIZE = 2 }

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

      result.must_equal [
        {
          'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
          'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
          'admin_ids' => [current_user.id], 'member_ids' => [member.id, current_user.id]
        },
        {
          'object_type' => 'user', 'id' => member.id, 'name' => 'Jane Doe',
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => 'around'
        },
        {
          'object_type' => 'user', 'id' => current_user.id, 'name' => 'John Doe',
          'status' => 'away', 'idle_duration' => nil, 'status_text' => 'be back soon', 'token' => current_user.token
        },
        {
          'object_type' => 'message', 'id' => m1.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hey guys', 'mentioned_user_ids' => [],
          'image_url' => nil, 'image_thumb_url' => nil, 'likes_count' => 0, 'created_at' => m1.created_at
        },
        {
          'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id,
          'user_id' => current_user.id, 'text' => 'oh hai', 'mentioned_user_ids' => [],
          'image_url' => nil, 'image_thumb_url' => nil, 'likes_count' => 0, 'created_at' => m2.created_at
        },
        {
          'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hey!', 'mentioned_user_ids' => [],
          'image_url' => nil, 'image_thumb_url' => nil, 'likes_count' => 0, 'created_at' => m3.created_at
        }
      ]
    end
  end
end
