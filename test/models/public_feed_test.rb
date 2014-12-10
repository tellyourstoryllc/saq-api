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
      user1 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 2.minutes.ago,
                                                latitude: 39.9475787, longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 1.minute.ago, latitude: 39.7,
                                 longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, latitude: 40.0, longitude: -76.0)

      results = PublicFeed.paginate_feed(current_user, sort: 'newest', radius: 25)
      results.size.must_equal 2
      results[0].must_equal user2
      results[1].must_equal user1
    end

    it "must order by closest public story" do
      user1 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 2.minutes.ago,
                                 latitude: 39.9475787, longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 1.minute.ago,
                                 latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, latitude: 40.0, longitude: -76.0)

      results = PublicFeed.paginate_feed(current_user, sort: 'closest', latitude: 39.98, longitude: -75.152)
      results[0].must_equal user1
      results[1].must_equal user2
    end

    it "must order by closest public story with explicit radius" do
      user1 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 2.minutes.ago,
                                 latitude: 39.9475787, longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 1.minute.ago,
                                 latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, last_public_story_created_at: 5.minutes.ago, latitude: 45.0,
                         longitude: -78.0)

      results = PublicFeed.paginate_feed(current_user, sort: 'closest', latitude: 39.9475787, longitude: -75.1564073, radius: 25)
      results.size.must_equal 3
      results[0].must_equal user1
      results[1].must_equal user2
    end

  end
end
