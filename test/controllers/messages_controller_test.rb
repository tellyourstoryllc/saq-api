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

        result.must_equal([{'object_type' => 'message', 'id' => message_id, 'group_id' => group.id,
                          'user_id' => current_user.id, 'text' => text, 'created_at' => now.to_i}])
        group.message_ids.last.to_i.must_equal message_id
      end
    end
  end
end
