require "test_helper"

describe SessionsController do
  describe "POST /login" do
    it "must not log in user when credentials are incorrect" do
      post :create, {login: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Incorrect credentials.'})

      FactoryGirl.create(:account, password: 'asdf', user_attributes: {name: 'John'}, emails_attributes: [{email: 'login_test@example.com'}])
      post :create, {login: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Incorrect credentials.'})
    end

    it "must not log in user when the user has no password nor Facebook id" do
      FactoryGirl.create(:account, user_attributes: {name: 'John'}, emails_attributes: [{email: 'login_test@example.com'}])
      post :create, {login: 'login_test@example.com', password: 'incorrect'}
      result.must_equal('error' => {'message' => 'Incorrect credentials.'})
    end

    it "must log in account when email and password are correct" do
      user = FactoryGirl.create(:user)
      account = FactoryGirl.create(:account, user_id: user.id, password: 'asdf', emails_attributes: [{email: 'login_test@example.com'}])

      post :create, {login: 'login_test@example.com', password: 'asdf'}

      result.size.must_equal 2
      result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => user.name, 'username' => user.username, 'token' => user.token,
        'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil, 'avatar_url' => nil}
      result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
        'facebook_id' => nil, 'time_zone' => 'America/New_York'}
    end

    it "must log in account when password and any of the user's emails are correct" do
      user = FactoryGirl.create(:user)
      account = FactoryGirl.create(:account, user_id: user.id, password: 'asdf',
                                   emails_attributes: [{email: 'login_test1@example.com'}, {email: 'login_test2@example.com'}])

      post :create, {login: 'login_test2@example.com', password: 'asdf'}

      result.size.must_equal 2
      result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => user.name, 'username' => user.username, 'token' => user.token,
        'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil, 'avatar_url' => nil}
      result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
        'facebook_id' => nil, 'time_zone' => 'America/New_York'}
    end

    it "must log in account when Facebook credentials are correct" do
      api = 'api'
      def api.get_object(id); {'id' => '100002345'} end

      Koala::Facebook::API.stub :new, api do
        user = FactoryGirl.create(:user)
        account = FactoryGirl.create(:account, user_id: user.id, facebook_id: '100002345', facebook_token: 'fb_asdf1234',
                                     emails_attributes: [{email: 'login_test@example.com'}])

        post :create, {facebook_id: '100002345', facebook_token: 'fb_asdf1234'}

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => user.name, 'username' => user.username, 'token' => user.token,
          'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil, 'avatar_url' => nil}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
          'facebook_id' => '100002345', 'time_zone' => 'America/New_York'}
      end
    end
  end

  it "must log in account when the invite token correct" do
    user = FactoryGirl.create(:user)
    sender = FactoryGirl.create(:user)
    FactoryGirl.create(:account, user_id: sender.id)
    account = FactoryGirl.create(:account, user_id: user.id)
    invite = FactoryGirl.create(:invite, sender_id: sender.id, recipient_id: user.id, invited_email: 'test@example.com')

    post :create, {invite_token: invite.invite_token}

    result.size.must_equal 2
    result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => user.name, 'username' => user.username, 'token' => user.token,
      'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil,
      'avatar_url' => nil}
    result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id, 'one_to_one_wallpaper_url' => nil,
      'facebook_id' => nil, 'time_zone' => 'America/New_York', 'needs_password' => true}
  end

  it "must not log in account when the invite token correct but the account is registered" do
    user = FactoryGirl.create(:user)
    sender = FactoryGirl.create(:user)
    FactoryGirl.create(:account, user_id: sender.id, password: 'asdf1234')
    account = FactoryGirl.create(:account, user_id: user.id, password: 'asdf1234', registered: true)
    invite = FactoryGirl.create(:invite, sender_id: sender.id, recipient_id: user.id, invited_email: 'test@example.com')

    post :create, {invite_token: invite.invite_token}
    result.must_equal('error' => {'message' => 'Incorrect credentials.'})
  end
end
