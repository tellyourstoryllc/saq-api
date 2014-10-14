require "test_helper"

describe MessagesController do
  describe "POST /messages/create" do
    describe "new 1-1" do
      it "must not create a message for a new 1-1 if sender is not allowed (no relationship)" do
        member = FactoryGirl.create(:registered_user)
        one_to_one_id = OneToOne.id_for_user_ids(current_user.id, member.id)
        text = 'hey'

        post :create, {one_to_one_ids: one_to_one_id, text: text, token: current_user.token}

        result.must_equal []

        current_user.one_to_one_ids.members.wont_include one_to_one_id
        current_user.one_to_one_user_ids.members.wont_include member.id

        member.one_to_one_ids.members.wont_include one_to_one_id
        member.one_to_one_user_ids.members.wont_include current_user.id
      end

      it "must not create a message for a new 1-1 if sender is not allowed (recipient has sender in contacts)" do
        member = FactoryGirl.create(:registered_user)
        ContactInviter.new(member).add_user(member, current_user)

        one_to_one_id = OneToOne.id_for_user_ids(current_user.id, member.id)
        text = 'hey'

        post :create, {one_to_one_ids: one_to_one_id, text: text, token: current_user.token}

        result.must_equal []

        current_user.one_to_one_ids.members.wont_include one_to_one_id
        current_user.one_to_one_user_ids.members.wont_include member.id

        member.one_to_one_ids.members.wont_include one_to_one_id
        member.one_to_one_user_ids.members.wont_include current_user.id
      end

      it "must not create a message for a new 1-1 if sender is not allowed (recipient added sender as contact and friend)" do
        member = FactoryGirl.create(:registered_user)
        ContactInviter.new(member).add_user(member, current_user)
        member.add_friend(current_user)

        one_to_one_id = OneToOne.id_for_user_ids(current_user.id, member.id)
        text = 'hey'

        post :create, {one_to_one_ids: one_to_one_id, text: text, token: current_user.token}

        result.must_equal []

        current_user.one_to_one_ids.members.wont_include one_to_one_id
        current_user.one_to_one_user_ids.members.wont_include member.id

        member.one_to_one_ids.members.wont_include one_to_one_id
        member.one_to_one_user_ids.members.wont_include current_user.id
      end

      it "must create a message for a new 1-1 if sender is allowed (sender added recipient as contact)" do
        member = FactoryGirl.create(:registered_user)
        ContactInviter.new(current_user).add_user(current_user, member)

        one_to_one_id = OneToOne.id_for_user_ids(current_user.id, member.id)
        text = 'hey'

        Time.stub :current, now = Time.parse('2013-10-07 15:08') do
          post :create, {one_to_one_ids: one_to_one_id, text: text, token: current_user.token}
          one_to_one = OneToOne.new(id: one_to_one_id)
          message_id = one_to_one.message_ids.last

          result_must_include 'message', message_id, {'object_type' => 'message', 'id' => message_id,
            'group_id' => nil, 'one_to_one_id' => one_to_one.id,
            'user_id' => current_user.id, 'rank' => 1, 'text' => text,
            'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil,
            'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}

          current_user.one_to_one_ids.members.must_include one_to_one.id
          current_user.one_to_one_user_ids.members.must_include member.id

          member.one_to_one_ids.members.must_include one_to_one.id
          member.one_to_one_user_ids.members.must_include current_user.id
        end
      end

      it "must create a message for a new 1-1 if sender is allowed (sender added recipient as friend)" do
        member = FactoryGirl.create(:registered_user)
        current_user.add_friend(member)

        one_to_one_id = OneToOne.id_for_user_ids(current_user.id, member.id)
        text = 'hey'

        Time.stub :current, now = Time.parse('2013-10-07 15:08') do
          post :create, {one_to_one_ids: one_to_one_id, text: text, token: current_user.token}
          one_to_one = OneToOne.new(id: one_to_one_id)
          message_id = one_to_one.message_ids.last

          result_must_include 'message', message_id, {'object_type' => 'message', 'id' => message_id,
            'group_id' => nil, 'one_to_one_id' => one_to_one.id,
            'user_id' => current_user.id, 'rank' => 1, 'text' => text,
            'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil,
            'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
            'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}

          current_user.one_to_one_ids.members.must_include one_to_one.id
          current_user.one_to_one_user_ids.members.must_include member.id

          member.one_to_one_ids.members.must_include one_to_one.id
          member.one_to_one_user_ids.members.must_include current_user.id
        end
      end
    end


    it "must create a message for an existing 1-1" do
      member = FactoryGirl.create(:registered_user)
      ContactInviter.new(current_user).add_user(current_user, member)

      one_to_one = OneToOne.new(creator_id: current_user.id, sender_id: current_user.id, recipient_id: member.id)
      raise '1-1 not saved' unless one_to_one.save

      text = 'hey'

      Time.stub :current, now = Time.parse('2013-10-07 15:08') do
        post :create, {one_to_one_ids: one_to_one.id, text: text, token: current_user.token}
        message_id = one_to_one.message_ids.last

        result_must_include 'message', message_id, {'object_type' => 'message', 'id' => message_id,
          'group_id' => nil, 'one_to_one_id' => one_to_one.id,
          'user_id' => current_user.id, 'rank' => 1, 'text' => text,
          'mentioned_user_ids' => [], 'attachment_url' => nil, 'attachment_content_type' => nil,
          'attachment_preview_url' => nil, 'attachment_preview_width' => nil, 'attachment_preview_height' => nil,
          'client_metadata' => nil, 'likes_count' => 0, 'created_at' => now.to_i}

        current_user.one_to_one_ids.members.must_include one_to_one.id
        current_user.one_to_one_user_ids.members.must_include member.id

        member.one_to_one_ids.members.must_include one_to_one.id
        member.one_to_one_user_ids.members.must_include current_user.id
      end
    end
  end
end
