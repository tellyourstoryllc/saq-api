require "test_helper"

describe GroupsController do
  describe "POST /groups/create" do
    describe "invalid" do
      it "must not create a group if it's invalid" do
        post :create, {token: current_user.token}
        result.must_equal('error' => {'message' => 'error'})
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
end
