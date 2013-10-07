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


    describe "GET /groups/:id" do
      it "must not return the group if the user is not a member" do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user)
        group.add_member(member)

        get :show, {id: group.id, token: current_user.token}
        result.must_equal('error' => {'message' => 'Sorry, that could not be found.'})
      end

      it "must return the group, its users, and its most recent page of messages" do
        group = FactoryGirl.create(:group)
        member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

        group.add_admin(current_user)
        group.add_member(current_user)
        group.add_member(member)

        current_user.update!(status: 'away', status_text: 'be back soon')

        message = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
        message.save

        get :show, {id: group.id, token: current_user.token}

        result.must_equal [
          {
            'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
            'join_url' => "http://test.host/join/#{group.join_code}", 'topic' => nil,
            'admin_ids' => [current_user.id], 'member_ids' => [member.id, current_user.id]
          },
          {
            'object_type' => 'user', 'id' => member.id, 'name' => 'Jane Doe',
            'status' => 'available', 'status_text' => 'around'
          },
          {
            'object_type' => 'user', 'id' => current_user.id, 'name' => 'John Doe',
            'status' => 'away', 'status_text' => 'be back soon', 'token' => current_user.token
          },
          {
            'object_type' => 'message', 'id' => message.id, 'group_id' => group.id,
            'user_id' => member.id, 'text' => 'hey guys', 'created_at' => message.created_at
          }
        ]
      end
    end
  end
end
