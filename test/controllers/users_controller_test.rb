require "test_helper"

describe UsersController do
  describe "POST /users" do
    describe "invalid" do
      it "must not create a user if it's invalid" do
        post :create
        result.must_equal('error' => {'message' => 'error'})
      end
    end


    describe "valid" do
      it "must create a user" do
        post :create, {name: 'John Doe', email: 'joe@example.com', password: 'asdf'}

        user = User.last
        result.must_equal [{'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'token' => user.token}]
      end

      it "must create a user and a group" do
        post :create, {name: 'John Doe', email: 'joe@example.com', password: 'asdf', group_name: 'Cool Dudes'}

        user = User.last
        group = Group.last

        result.must_equal [
          {'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'token' => user.token},
          {'object_type' => 'group', 'id' => group.id, 'creator_id' => user.id, 'name' => 'Cool Dudes', 'join_url' => "http://test.host/join/#{group.join_code}"}
        ]
      end
    end
  end
end
