require "test_helper"

describe SessionsController do
  describe "POST /login" do
    it "must not log in user when credentials are incorrect" do
      post :create, {email: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Invalid credentials.'})

      FactoryGirl.create(:account, email: 'login_test@example.com', password: 'asdf')
      post :create, {email: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Invalid credentials.'})
    end

    it "must log in account when credentials are correct" do
      user = FactoryGirl.create(:user)
      account = FactoryGirl.create(:account, user_id: user.id, email: 'login_test@example.com', password: 'asdf')

      post :create, {email: 'login_test@example.com', password: 'asdf'}

      result.must_equal [
        {'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'username' => user.username, 'token' => user.token,
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil,
          'avatar_url' => 'https://s3.amazonaws.com/TESTbray.media.chat.com/defaults/thumb_avatar_image.png'},
        {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'email' => 'login_test@example.com', 'one_to_one_wallpaper_url' => nil}
      ]
    end
  end
end
