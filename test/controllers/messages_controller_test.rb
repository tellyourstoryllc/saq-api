require "test_helper"

describe MessagesController do
  describe "POST /groups/:group_id/messages/create" do
    it "must not create a message if the user is not a member" do
      group = FactoryGirl.create(:group)
      post :create, {group_id: group.id, text: 'hey everyone', token: current_user.token}
      result.must_equal('error' => {'message' => 'Sorry, that could not be found.'})
    end

    it "must create a message" do
      group = FactoryGirl.create(:group)
      group.add_member(current_user)
      text = 'hey everyone'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, token: current_user.token}

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'user_id' => current_user.id,
                          'text' => text, 'mentioned_user_ids' => [], 'image_url' => nil,
                          'created_at' => now.to_i}])
        group.message_ids.last.to_i.must_equal message_id
      end
    end

    it "must create a message with one mention" do
      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      user = FactoryGirl.create(:user)
      group.add_member(user)

      text = 'hey everyone'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: user.id, token: current_user.token}

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'user_id' => current_user.id,
                          'text' => text, 'mentioned_user_ids' => [user.id], 'image_url' => nil,
                          'created_at' => now.to_i}])
        group.message_ids.last.to_i.must_equal message_id
      end
    end

    it "must create a message with multiple mentions" do
      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      u1 = FactoryGirl.create(:user)
      group.add_member(u1)

      u2 = FactoryGirl.create(:user)
      group.add_member(u2)

      text = 'hey everyone'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: [u1.id, u2.id].join(','), token: current_user.token}

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'user_id' => current_user.id,
                          'text' => text, 'mentioned_user_ids' => [u1.id, u2.id], 'image_url' => nil,
                          'created_at' => now.to_i}])
        group.message_ids.last.to_i.must_equal message_id
      end
    end

    it "must create a message and sanitize mentions" do
      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      u1 = FactoryGirl.create(:user)
      group.add_member(u1)

      text = 'hey everyone'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: [99999, u1.id].join(','), token: current_user.token}

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'user_id' => current_user.id,
                          'text' => text, 'mentioned_user_ids' => [u1.id], 'image_url' => nil,
                          'created_at' => now.to_i}])
        group.message_ids.last.to_i.must_equal message_id
      end
    end

    it "must create a message and allow an @all mention" do
      group = FactoryGirl.create(:group)
      group.add_member(current_user)

      text = 'hey everyone'
      message_id = Message.redis.get('message_autoincrement_id').to_i + 1

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {group_id: group.id, text: text, mentioned_user_ids: '-1', token: current_user.token}

        result.must_equal([{'object_type' => 'message', 'id' => message_id,
                          'group_id' => group.id, 'user_id' => current_user.id,
                          'text' => text, 'mentioned_user_ids' => [-1], 'image_url' => nil,
                          'created_at' => now.to_i}])
        group.message_ids.last.to_i.must_equal message_id
      end
    end
  end


  describe "GET /groups/:group_id/messages" do
    it "must return the most recent page of messages" do
      silence_warnings{ Group::PAGE_SIZE = 2 }

      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

      group.add_member(current_user)
      group.add_member(member)

      m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
      m1.save

      m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
      m2.save

      m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hi again')
      m3.save

      get :index, {group_id: group.id, token: current_user.token}

      result.must_equal [
        {
          'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id,
          'user_id' => current_user.id, 'text' => 'oh hai', 'mentioned_user_ids' => [],
          'image_url' => nil, 'created_at' => m2.created_at
        },
        {
          'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hi again', 'mentioned_user_ids' => [],
          'image_url' => nil, 'created_at' => m3.created_at
        }
      ]
    end

    it "must return the most recent page of messages with a given limit" do
      silence_warnings{ Group::PAGE_SIZE = 2 }

      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

      group.add_member(current_user)
      group.add_member(member)

      m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
      m1.save

      m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
      m2.save

      m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hi again')
      m3.save

      get :index, {group_id: group.id, limit: 3, token: current_user.token}

      result.must_equal [
        {
          'object_type' => 'message', 'id' => m1.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hey guys', 'mentioned_user_ids' => [],
          'image_url' => nil, 'created_at' => m1.created_at
        },
        {
          'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id,
          'user_id' => current_user.id, 'text' => 'oh hai', 'mentioned_user_ids' => [],
          'image_url' => nil, 'created_at' => m2.created_at
        },
        {
          'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hi again', 'mentioned_user_ids' => [],
          'image_url' => nil, 'created_at' => m3.created_at
        }
      ]
    end

    it "must return the most recent page of messages, starting from a given message id" do
      silence_warnings{ Group::PAGE_SIZE = 2 }

      group = FactoryGirl.create(:group)
      member = FactoryGirl.create(:user, name: 'Jane Doe', status: 'available', status_text: 'around')

      group.add_member(current_user)
      group.add_member(member)

      m1 = Message.new(group_id: group.id, user_id: member.id, text: 'hey guys')
      m1.save

      m2 = Message.new(group_id: group.id, user_id: current_user.id, text: 'oh hai')
      m2.save

      m3 = Message.new(group_id: group.id, user_id: member.id, text: 'hi again')
      m3.save

      m4 = Message.new(group_id: group.id, user_id: member.id, text: 'hello?')
      m4.save

      get :index, {group_id: group.id, last_message_id: m4.id, token: current_user.token}

      result.must_equal [
        {
          'object_type' => 'message', 'id' => m2.id, 'group_id' => group.id,
          'user_id' => current_user.id, 'text' => 'oh hai', 'mentioned_user_ids' => [],
          'image_url' => nil, 'created_at' => m2.created_at
        },
        {
          'object_type' => 'message', 'id' => m3.id, 'group_id' => group.id,
          'user_id' => member.id, 'text' => 'hi again', 'mentioned_user_ids' => [],
          'image_url' => nil, 'created_at' => m3.created_at
        }
      ]
    end
  end
end
