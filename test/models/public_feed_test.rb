require "test_helper"

class PublicFeedTest < ActiveSupport::TestCase
  describe "PublicFeed#paginate_feed" do

    it "must not return deactivated or unregistered users" do
      valid_user = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 2.minutes.ago)
      deactivated_user = FactoryGirl.create(:registered_user, :female, :deactivated, last_public_story_created_at: 1.minute.ago)
      unregistered_user = FactoryGirl.create(:user, :female, last_public_story_created_at: 1.minute.ago)
      FactoryGirl.create(:account, :unregistered, user: unregistered_user)

      results = PublicFeed.paginate_feed(current_user, {})
      results.must_be :present?
      results.must_include valid_user
      results.wont_include deactivated_user
      results.wont_include unregistered_user
    end

    it "must order by newest public story" do
      user1 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 2.minutes.ago)
      user2 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 1.minute.ago)
      user3 = FactoryGirl.create(:registered_user, :female)

      results = PublicFeed.paginate_feed(current_user, sort: 'newest')
      results[0].must_equal user2
      results[1].must_equal user1
      results.wont_include user3
    end

    it "must order by newest public story with radius" do
      user1 = FactoryGirl.create(:registered_user, :female, last_public_story_id: 'awv14vmc1l',
                                 last_public_story_created_at: 2.minutes.ago, last_public_story_latitude: 39.9475787,
                                 last_public_story_longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :female, last_public_story_id: 'vmqv10xmao',
                                 last_public_story_created_at: 1.minute.ago, last_public_story_latitude: 39.7,
                                 last_public_story_longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 3.minutes.ago,
                         last_public_story_latitude: 40.0, last_public_story_longitude: -76.0)

      sl1 = StoriesList.new(creator_id: user1.id, viewer_id: current_user.id)
      story1 = Story.new(id: 'awv14vmc1l', user_id: user1.id, stories_list_id: sl1.id, text: 'foo')
      story1.save

      sl2 = StoriesList.new(creator_id: user2.id, viewer_id: current_user.id)
      story2 = Story.new(id: 'vmqv10xmao', user_id: user2.id, stories_list_id: sl2.id, text: 'bar')
      story2.save

      results = PublicFeed.paginate_feed(current_user, sort: 'newest', radius: 25, latitude: 39.9510010, longitude: -75.1627290)

      results.size.must_equal 4

      results[0].must_equal user2
      results[1].must_equal user1

      results[2].class.must_equal Story
      results[2].id.must_equal 'vmqv10xmao'

      results[3].class.must_equal Story
      results[3].id.must_equal 'awv14vmc1l'
    end

    it "must order by closest public story" do
      user1 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 2.minutes.ago,
                                 last_public_story_latitude: 39.9475787, last_public_story_longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 1.minute.ago,
                                 last_public_story_latitude: 39.7, last_public_story_longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, latitude: 40.0, longitude: -76.0)

      results = PublicFeed.paginate_feed(current_user, sort: 'closest', latitude: 39.98, longitude: -75.152)
      results[0].must_equal user1
      results[1].must_equal user2
    end

    it "must order by closest public story" do
      user1 = FactoryGirl.create(:registered_user, :female, last_public_story_id: 'awv14vmc1l',
                                 last_public_story_created_at: 2.minutes.ago, last_public_story_latitude: 39.9475787,
                                 last_public_story_longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :female, last_public_story_id: 'vmqv10xmao',
                                 last_public_story_created_at: 1.minute.ago, last_public_story_latitude: 39.7,
                                 last_public_story_longitude: -75.2)

      sl1 = StoriesList.new(creator_id: user1.id, viewer_id: current_user.id)
      story1 = Story.new(id: 'awv14vmc1l', user_id: user1.id, stories_list_id: sl1.id, text: 'foo')
      story1.save

      sl2 = StoriesList.new(creator_id: user2.id, viewer_id: current_user.id)
      story2 = Story.new(id: 'vmqv10xmao', user_id: user2.id, stories_list_id: sl2.id, text: 'bar')
      story2.save

      results = PublicFeed.paginate_feed(current_user, sort: 'closest', latitude: 39.9510010, longitude: -75.1627290)

      results.size.must_equal 4

      results[0].must_equal user1
      results[1].must_equal user2

      results[2].class.must_equal Story
      results[2].id.must_equal 'awv14vmc1l'

      results[3].class.must_equal Story
      results[3].id.must_equal 'vmqv10xmao'
    end

  end
end
