require "test_helper"

describe UsersController do
  describe "POST /users/create" do
    describe "invalid" do
      #it "must not create a user if it's invalid" do
      #  post :create
      #  old_count = User.count
      #  result.must_equal('error' => {'message' => "Sorry, that could not be saved: Validation failed: User gender can't be blank."})
      #  User.count.must_equal old_count
      #end

      it "must not create a user using Facebook authentication if the given Facebook id and token are not valid" do
        stub_request(:any, /.*facebook.com/).to_return(body: '{}')

        post :create, {username: 'JohnDoe', email: 'joe@example.com', facebook_id: '100002345', facebook_token: 'invalidtoken'}
        old_count = User.count
        #result.must_equal('error' => {'message' => "Sorry, that could not be saved: Validation failed: Invalid Facebook credentials, User gender can't be blank."})
        result.must_equal('error' => {'message' => "Sorry, that could not be saved: Validation failed: Invalid Facebook credentials."})
        User.count.must_equal old_count
      end
    end


    describe "valid" do
      it "must create a user and account" do
        post :create, {username: 'JohnDoe', email: 'joe@example.com', password: 'asdf', gender: 'male'}

        user = User.order('created_at DESC').first
        account = Account.order('created_at DESC').first

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'JohnDoe', 'username' => 'JohnDoe',
          'token' => user.token, 'avatar_url' => nil}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}
      end

      it "must create a user and account without a password" do
        post :create, {username: 'JohnDoe', email: 'joe@example.com', gender: 'male'}

        user = User.order('created_at DESC').first
        account = Account.order('created_at DESC').first

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'JohnDoe', 'username' => 'JohnDoe',
          'token' => user.token, 'avatar_url' => nil, 'friend_code' => user.friend_code}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York', 'needs_password' => true}
      end

      it "must create a user and account without a username or password" do
        post :create, {email: 'joe@example.com', gender: 'male'}

        user = User.order('created_at DESC').first
        account = Account.order('created_at DESC').first

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => user.username, 'username' => user.username,
          'token' => user.token, 'avatar_url' => nil, 'friend_code' => user.friend_code}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York', 'needs_password' => true}

        user_hash = result.detect{ |r| r['object_type'] == 'user' && r['id'] == user.id }
        user_hash['username'].starts_with?('_user').must_equal true
      end

      it "must create a user and account without a username or password, and with additional attributes" do
        post :create, {email: 'joe@example.com', gender: 'male', latitude: '39.9525840', longitude: '-75.1652220',
                       location_name: 'Northern Liberties'}

        user = User.order('created_at DESC').first
        account = Account.order('created_at DESC').first

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => user.username, 'username' => user.username,
          'token' => user.token, 'avatar_url' => nil, 'gender' => 'male', 'latitude' => 39.9525840,
          'longitude' => -75.1652220, 'location_name' => 'Northern Liberties', 'friend_code' => user.friend_code}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York', 'needs_password' => true}

        user_hash = result.detect{ |r| r['object_type'] == 'user' && r['id'] == user.id }
        user_hash['username'].starts_with?('_user').must_equal true
      end

      it "must create a user and a group" do
        Time.stub :now, now = Time.parse('2013-12-26 15:08') do
          post :create, {username: 'JohnDoe', email: 'joe@example.com', password: 'asdf', gender: 'male', group_name: 'Cool Dudes'}

          user = User.order('created_at DESC').first
          account = Account.order('created_at DESC').first
          group = Group.order('created_at DESC').first

          result.size.must_equal 3
          result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => user.name,
            'username' => 'JohnDoe', 'token' => user.token, 'avatar_url' => nil, 'friend_code' => user.friend_code}

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
          post :create, {username: 'JohnDoe', email: 'joe@example.com', gender: 'male', facebook_id: '100002345', facebook_token: 'fb_asdf1234'}

          user = User.order('created_at DESC').first
          account = Account.order('created_at DESC').first

          result.size.must_equal 2
          result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'JohnDoe', 'username' => 'JohnDoe',
            'token' => user.token, 'avatar_url' => nil, 'friend_code' => user.friend_code}
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
          'token' => user.token, 'avatar_url' => nil, 'friend_code' => user.friend_code}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}

        User.count.must_equal user_count

        user.account.password_digest.wont_be_nil

        emails = user.emails
        emails.size.must_equal 2
        emails.last.email.must_equal 'bruce@example.com'
      end

      it "must update an existing user and account if the username hasn't yet been 'claimed'" do
        user = FactoryGirl.create(:user, username: 'BruceLee')
        account = FactoryGirl.create(:account, user_id: user.id)
        user_count = User.count

        post :create, {username: 'BruceLee', email: 'bruce@example.com', password: 'asdf'}

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'BruceLee', 'username' => 'BruceLee',
          'token' => user.token, 'avatar_url' => nil, 'registered' => true, 'friend_code' => user.friend_code}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}

        User.count.must_equal user_count

        user.account.password_digest.wont_be_nil
        user.account.registered?.must_equal true

        emails = user.emails
        emails.size.must_equal 2
        emails.last.email.must_equal 'bruce@example.com'
      end

      it "must not update an existing user and account via invite_token if the user is registered" do
        sender = FactoryGirl.create(:user)
        FactoryGirl.create(:account, user_id: sender.id)
        user = FactoryGirl.create(:user)
        FactoryGirl.create(:account, :registered, user_id: user.id)
        invite = FactoryGirl.create(:invite, sender_id: sender.id, recipient_id: user.id, invited_email: 'bruce@example.com')
        user_count = User.count

        post :create, {username: 'BruceLee', email: 'bruce@example.com', password: 'asdf', gender: 'male', invite_token: invite.invite_token}

        user = User.find_by(username: 'BruceLee')
        account = user.account

        result.size.must_equal 2
        result_must_include 'user', user.id, {'object_type' => 'user', 'id' => user.id, 'name' => 'BruceLee', 'username' => 'BruceLee',
          'token' => user.token, 'avatar_url' => nil, 'friend_code' => user.friend_code}
        result_must_include 'account', account.id, {'object_type' => 'account', 'id' => account.id, 'user_id' => user.id,
          'one_to_one_wallpaper_url' => nil, 'facebook_id' => nil, 'time_zone' => 'America/New_York'}

        User.count.must_equal user_count + 1
      end
    end
  end


  describe "POST /users/update" do
    it "must update the user" do
      FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')
      old_friend_code = current_user.friend_code

      post :update, {token: current_user.token, username: 'Johnny', status: 'away', status_text: 'be back soon',
                     latitude: '50.19361', longitude: '-74.0192', location_name: 'Anytown, USA'}

      result.size.must_equal 1
      result_must_include 'user', current_user.id, {'object_type' => 'user', 'id' => current_user.id, 'name' => 'Johnny',
        'username' => 'Johnny', 'token' => current_user.token, 'avatar_url' => nil, 'latitude' => 50.19361, 'longitude' => -74.0192,
        'location_name' => 'Anytown, USA', 'friend_code' => current_user.friend_code}

      current_user.reload.friend_code.must_equal old_friend_code
    end

    it "must update the user's friend_code" do
      FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')
      old_friend_code = current_user.friend_code

      post :update, {token: current_user.token, username: 'Johnny', status: 'away', status_text: 'be back soon',
                     latitude: '50.19361', longitude: '-74.0192', location_name: 'Anytown, USA', reset_friend_code: 'true'}

      result.size.must_equal 1
      result_must_include 'user', current_user.id, {'object_type' => 'user', 'id' => current_user.id, 'name' => 'Johnny',
        'username' => 'Johnny', 'token' => current_user.token, 'avatar_url' => nil, 'latitude' => 50.19361, 'longitude' => -74.0192,
        'location_name' => 'Anytown, USA'}

      current_user.reload.friend_code.wont_equal old_friend_code
    end

    it "must not update the user's status to idle" do
      FactoryGirl.create(:faye_client, user_id: current_user.id, status: 'active')
      post :update, {name: 'Johnny', status: 'idle', status_text: 'be back soon', token: current_user.token}
      result.must_equal('error' => {'message' => "Sorry, that could not be saved: Validation failed: Status is not included in the list."})
    end

    describe "when adding avatar image" do
      after do
        # Delete temp files for upload created by CarrierWave.
        FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads/tmp/[^.]*"])
      end

      let(:user) { FactoryGirl.create(:registered_user) }

      before do
        stub_request(:any, /#{Rails.configuration.app['aws']['bucket_name']}/).to_return(headers: { 'ETag' => 'abc' })
        @moderator_post = stub_request(:post, "#{Moderator.url}/api/photo/submit").to_return(body: '{}')
      end

      let(:image_file) { File.open(File.expand_path('test/data/rubygem.png')) }
      
      def uploaded_file_object
        filename = File.basename(image_file.path)

        ActionDispatch::Http::UploadedFile.new(
          tempfile: image_file,
          filename: filename,
          head: %Q{Content-Disposition: form-data; filename="#{filename}"},
          type: 'image/png'
        )
      end

      #it "should submit to the moderator" do
      #  post :update, {token: user.token, avatar_image_file: uploaded_file_object}
      #  assert_requested @moderator_post
      #  user.reload
      #  user.avatar_image.must_be :in_review?
      #end
    end
  end
end
