require "test_helper"

describe ConversationsController do
  describe "GET /conversations" do
    it "must not return any conversations if the user doesn't have any" do
      get :index, {token: current_user.token}
      result.must_equal []
    end

    it "must return 1-1s" do
      member = FactoryGirl.create(:registered_user)
      member.add_friend(current_user)

      o = OneToOne.new(creator_id: member.id, sender_id: member.id, recipient_id: current_user.id)
      raise 'not saved' unless o.save

      get :index, {token: current_user.token}

      result_must_include 'one_to_one', o.id, {'object_type' => 'one_to_one', 'id' => o.id,
        'last_message_at' => nil, 'last_seen_rank' => nil, 'last_deleted_rank' => nil, 'hidden' => false}
    end

    it "must return 1-1s but not their unseen messages if the 1-1 is pending" do
      member = FactoryGirl.create(:registered_user)
      member.add_friend(current_user)

      o = OneToOne.new(creator_id: member.id, sender_id: member.id, recipient_id: current_user.id)
      raise '1-1 not saved' unless o.save

      m = Message.new(one_to_one_id: o.id, user_id: member.id, text: 'hi')
      raise 'msg not saved' unless m.save

      get :index, {token: current_user.token}

      result_must_include 'one_to_one', o.id, {'object_type' => 'one_to_one', 'id' => o.id,
        'last_message_at' => m.created_at, 'last_seen_rank' => nil, 'last_deleted_rank' => nil, 'hidden' => false}

      result_wont_include 'message', m.id
    end

    it "must return 1-1s and their unseen messages if they're mutual friends" do
      member = FactoryGirl.create(:registered_user)
      member.add_friend(current_user)
      current_user.add_friend(member)

      o = OneToOne.new(creator_id: member.id, sender_id: member.id, recipient_id: current_user.id)
      raise '1-1 not saved' unless o.save

      m = Message.new(one_to_one_id: o.id, user_id: member.id, text: 'hi')
      raise 'msg not saved' unless m.save

      get :index, {token: current_user.token}

      result_must_include 'one_to_one', o.id, {'object_type' => 'one_to_one', 'id' => o.id,
        'last_message_at' => m.created_at, 'last_seen_rank' => nil, 'last_deleted_rank' => nil, 'hidden' => false}

      result_must_include 'message', m.id, {'object_type' => 'message', 'id' => m.id,
        'group_id' => nil, 'one_to_one_id' => o.id, 'user_id' => member.id, 'rank' => 1, 'text' => 'hi',
        'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil,
        'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
        'client_metadata' => nil, 'created_at' => m.created_at}
    end

    it "must return 1-1s and their unseen messages if the sender has the recipient in his contacts" do
      member = FactoryGirl.create(:registered_user)
      ContactInviter.add_user(member, current_user)

      o = OneToOne.new(creator_id: member.id, sender_id: member.id, recipient_id: current_user.id)
      raise '1-1 not saved' unless o.save

      m = Message.new(one_to_one_id: o.id, user_id: member.id, text: 'hi')
      raise 'msg not saved' unless m.save

      get :index, {token: current_user.token}

      result_must_include 'one_to_one', o.id, {'object_type' => 'one_to_one', 'id' => o.id,
        'last_message_at' => m.created_at, 'last_seen_rank' => nil, 'last_deleted_rank' => nil, 'hidden' => false}

      result_must_include 'message', m.id, {'object_type' => 'message', 'id' => m.id,
        'group_id' => nil, 'one_to_one_id' => o.id, 'user_id' => member.id, 'rank' => 1, 'text' => 'hi',
        'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil,
        'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
        'client_metadata' => nil, 'created_at' => m.created_at}
    end
  end
end
