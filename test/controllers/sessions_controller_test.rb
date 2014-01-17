require "test_helper"

describe SessionsController do
  describe "POST /login" do
    it "must not log in user when credentials are incorrect" do
      post :create, {email: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Incorrect credentials.'})

      FactoryGirl.create(:account, password: 'asdf', user_attributes: {name: 'John'}, emails_attributes: [{email: 'login_test@example.com'}])
      post :create, {email: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Incorrect credentials.'})
    end

    it "must not log in user when the user has no password nor Facebook id" do
      FactoryGirl.create(:account, user_attributes: {name: 'John'}, emails_attributes: [{email: 'login_test@example.com'}])
      post :create, {email: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Incorrect credentials.'})
    end

    it "must log in account when email and password are correct" do
      user = FactoryGirl.create(:user)
      account = FactoryGirl.create(:account, user_id: user.id, password: 'asdf', emails_attributes: [{email: 'login_test@example.com'}])

      post :create, {email: 'login_test@example.com', password: 'asdf'}

      result.must_equal [
        {'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'username' => user.username, 'token' => user.token,
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil,
          'avatar_url' => nil},
        {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
          'facebook_id' => nil, 'time_zone' => 'America/New_York'}
      ]
    end

    it "must log in account when password and any of the user's emails are correct" do
      user = FactoryGirl.create(:user)
      account = FactoryGirl.create(:account, user_id: user.id, password: 'asdf',
                                   emails_attributes: [{email: 'login_test1@example.com'}, {email: 'login_test2@example.com'}])

      post :create, {email: 'login_test2@example.com', password: 'asdf'}

      result.must_equal [
        {'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'username' => user.username, 'token' => user.token,
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil,
          'avatar_url' => nil},
        {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
          'facebook_id' => nil, 'time_zone' => 'America/New_York'}
      ]
    end

    it "must log in account when Facebook credentials are correct" do
      api = 'api'
      def api.get_object(id); {'id' => '100002345'} end

      Koala::Facebook::API.stub :new, api do
        user = FactoryGirl.create(:user)
        account = FactoryGirl.create(:account, user_id: user.id, facebook_id: '100002345', facebook_token: 'fb_asdf1234',
                                     emails_attributes: [{email: 'login_test@example.com'}])

        post :create, {facebook_id: '100002345', facebook_token: 'fb_asdf1234'}

        result.must_equal [
          {'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'username' => user.username, 'token' => user.token,
            'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil,
            'avatar_url' => nil},
          {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
            'facebook_id' => '100002345', 'time_zone' => 'America/New_York'}
        ]
      end
    end
  end

  it "must log in account when the invite token correct" do
    user = FactoryGirl.create(:user)
    account = FactoryGirl.create(:account, user_id: user.id)
    invite = FactoryGirl.create(:invite, recipient_id: user.id)

    post :create, {invite_token: invite.invite_token}

    result.must_equal [
      {'object_type' => 'user', 'id' => user.id, 'name' => 'John Doe', 'username' => user.username, 'token' => user.token,
        'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil,
        'avatar_url' => nil},
      {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
        'facebook_id' => nil, 'time_zone' => 'America/New_York'}
    ]
  end
end
