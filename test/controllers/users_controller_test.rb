require "test_helper"

describe UsersController do
  describe "POST /users/create" do
    describe "invalid" do
      it "must not create a user if it's invalid" do
        post :create
        old_count = User.count
        result.must_equal('error' => {'message' => "Sorry, that could not be saved: Validation failed: Email is invalid."})
        User.count.must_equal old_count
      end

      it "must not create a user using Facebook authentication if the given Facebook id and token are not valid" do
        stub_request(:any, /.*facebook.com/).to_return(body: {})

        post :create, {username: 'JohnDoe', email: 'joe@example.com', facebook_id: '100002345', facebook_token: 'invalidtoken'}
        old_count = User.count
        result.must_equal('error' => {'message' => 'Sorry, that could not be saved: Validation failed: Invalid Facebook credentials.'})
        User.count.must_equal old_count
      end
    end


    describe "valid" do
      it "must create a user and account" do
        post :create, {username: 'JohnDoe', email: 'joe@example.com', password: 'asdf'}

        user = User.last
        account = Account.last

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'JohnDoe', 'username' => 'JohnDoe',
          'token' => user.token, 'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
          'client_type' => nil, 'avatar_url' => nil}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}
      end

      it "must create a user and account without a password" do
        post :create, {username: 'JohnDoe', email: 'joe@example.com'}

        user = User.last
        account = Account.last

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'JohnDoe', 'username' => 'JohnDoe',
          'token' => user.token, 'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
          'client_type' => nil, 'avatar_url' => nil}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York', 'needs_password' => true}
      end

      it "must create a user and a group" do
        Time.stub :now, now = Time.parse('2013-12-26 15:08') do
          post :create, {username: 'JohnDoe', email: 'joe@example.com', password: 'asdf', group_name: 'Cool Dudes'}

          user = User.order('created_at DESC').last
          account = Account.last
          group = Group.order('created_at DESC').last

          result.size.must_equal 3
          result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'JohnDoe',
            'username' => 'JohnDoe', 'token' => user.token, 'status' => 'unavailable',
            'idle_duration' => nil, 'status_text' => nil, 'client_type' => nil, 'avatar_url' => nil}

          result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
            'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}

          result_must_include 'group', group.id, {'object_type' => 'group', 'id' => group.id, 'name' => 'Cool Dudes',
            'join_url' => "http://test.host/v/#{group.join_code}", 'topic' => nil,
            'avatar_url' => nil, 'wallpaper_url' => nil, 'admin_ids' => [user.id], 'member_ids' => [user.id],
            'last_message_at' => nil, 'last_seen_rank' => nil, 'hidden' => nil, 'created_at' => now.to_i}
        end
      end

      it "must create a user and account using Facebook authentication" do
        api = 'api'
        def api.get_object(id); {'id' => '100002345'} end
        def api.get_connections(id, connection); [] end

        Koala::Facebook::API.stub :new, api do
          post :create, {username: 'JohnDoe', email: 'joe@example.com', facebook_id: '100002345', facebook_token: 'fb_asdf1234'}

          user = User.last
          account = Account.last

          result.size.must_equal 2
          result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'JohnDoe', 'username' => 'JohnDoe',
            'token' => user.token, 'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
            'client_type' => nil, 'avatar_url' => nil}
          result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
            'one_to_one_wallpaper_url' => nil, 'facebook_id' => '100002345', 'time_zone' => 'America/New_York'}
        end
      end

      it "must update an existing user and account via invite_token" do
        sender = FactoryGirl.create(:user)
        FactoryGirl.create(:account, user_id: sender.id)
        user = FactoryGirl.create(:user)
        account = FactoryGirl.create(:account, user_id: user.id)
        invite = FactoryGirl.create(:invite, sender_id: sender.id, recipient_id: user.id, invited_email: 'bruce@example.com')
        user_count = User.count

        post :create, {username: 'BruceLee', email: 'bruce@example.com', password: 'asdf', invite_token: invite.invite_token}

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'BruceLee', 'username' => 'BruceLee',
          'token' => user.token, 'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
          'client_type' => nil, 'avatar_url' => nil}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}

        User.count.must_equal user_count

        user.account.password_digest.wont_be_nil

        emails = user.emails
        emails.size.must_equal 2
        emails.last.email.must_equal 'bruce@example.com'
      end

      it "must not update an existing user and account via invite_token if the user has login credentials" do
        sender = FactoryGirl.create(:user)
        FactoryGirl.create(:account, user_id: sender.id)
        user = FactoryGirl.create(:user)
        account = FactoryGirl.create(:account, user_id: user.id, password: 'asdf1234')
        invite = FactoryGirl.create(:invite, sender_id: sender.id, recipient_id: user.id, invited_email: 'bruce@example.com')
        user_count = User.count

        post :create, {username: 'BruceLee', email: 'bruce@example.com', password: 'asdf', invite_token: invite.invite_token}

        user = User.find_by(username: 'BruceLee')
        account = user.account

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'BruceLee', 'username' => 'BruceLee',
          'token' => user.token, 'status' => 'unavailable', 'idle_duration' => nil, 'status_text' => nil,
          'client_type' => nil, 'avatar_url' => nil}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}

        User.count.must_equal user_count + 1
      end
    end
  end


  describe "POST /users/update" do
    it "must update the user" do
      FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')
      post :update, {username: 'Johnny', status: 'away', status_text: 'be back soon', token: current_user.token}

      result.size.must_equal 1
      result_must_include 'user', current_user.id, {'object_type' => 'user', 'id' => current_user.id, 'name' => 'Johnny',
        'username' => 'Johnny', 'token' => current_user.token,
        'status' => 'away', 'idle_duration' => nil, 'status_text' => 'be back soon', 'client_type' => 'web',
        'avatar_url' => nil}
    end

    it "must not update the user's status to idle" do
      FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')
      post :update, {name: 'Johnny', status: 'idle', status_text: 'be back soon', token: current_user.token}
      result.must_equal('error' => {'message' => "Sorry, that could not be saved: Validation failed: Status is not included in the list."})
    end
  end
end
