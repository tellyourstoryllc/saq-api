require "test_helper"

describe UsersController do
  describe "POST /users/create" do
    describe "invalid" do
      it "must not create a user if it's invalid" do
        post :create
        result.must_equal('error' => {'message' => "Validation failed: Name can't be blank, Email is invalid, Password can't be blank"})
      end
    end


    describe "valid" do
      it "must create a user" do
        post :create, {name: 'John Doe', email: 'joe@example.com', password: 'asdf'}

        user = User.last
        result.must_equal [{'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe',
          'token' => user.token, 'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
          'avatar_url' => 'https://s3.amazonaws.com/TESTbray.media.chat.com/defaults/thumb_avatar_image.png'}]
      end

      it "must create a user and a group" do
        post :create, {name: 'John Doe', email: 'joe@example.com', password: 'asdf', group_name: 'Cool Dudes'}

        user = User.last
        group = Group.last

        result.must_equal [
          {'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'token' => user.token,
            'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
            'avatar_url' => 'https://s3.amazonaws.com/TESTbray.media.chat.com/defaults/thumb_avatar_image.png'},
          {'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes', 'join_url' => "http://test.host/join/#{group.join_code}",
            'topic' => nil, 'admin_ids' => [user.id], 'member_ids' => [user.id]}
        ]
      end
    end
  end


  describe "POST /users/update" do
    it "must update the user" do
      FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')
      post :update, {name: 'Johnny', status: 'away', status_text: 'be back soon', token: current_user.token}

      result.must_equal [
        {'object_type' => 'user', 'id' => current_user.id, 'name' => 'Johnny', 'token' => current_user.token,
          'status' => 'away', 'idle_duration' => nil, 'status_text' => 'be back soon',
          'avatar_url' => 'https://s3.amazonaws.com/TESTbray.media.chat.com/defaults/thumb_avatar_image.png'}
      ]
    end

    it "must not update the user's status to idle" do
      FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')
      proc{ post :update, {name: 'Johnny', status: 'idle', status_text: 'be back soon', token: current_user.token} }.must_raise(ActiveRecord::RecordInvalid)
    end
  end
end
