require "test_helper"

class PublicFeedTest < ActiveSupport::TestCase
  describe "PublicFeed#paginate_feed" do

    it "must not return deactivated or unregistered users" do
      current_user = FactoryGirl.create(:registered_user, :female)
      deactivated_user = FactoryGirl.create(:registered_user, :female, :deactivated)
      unregistered_user = FactoryGirl.create(:user, :female)
      FactoryGirl.create(:account, :unregistered, user: unregistered_user)

      results = PublicFeed.paginate_feed(current_user, {})
      results.must_be :present?
      results.must_include current_user
      results.wont_include deactivated_user
      results.wont_include unregistered_user
    end

    it "must order by newest" do
      user1 = current_user = FactoryGirl.create(:registered_user, :female, created_at: 2.minutes.ago)
      user2 = FactoryGirl.create(:registered_user, :female, created_at: 1.minute.ago)

      results = PublicFeed.paginate_feed(current_user, sort: 'newest')
      results[0].must_equal user2
      results[1].must_equal user1
    end

    it "must order by newest with radius" do
      user1 = current_user = FactoryGirl.create(:registered_user, :female, created_at: 2.minutes.ago, latitude: 39.9475787, longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :female, created_at: 1.minute.ago, latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, latitude: 40.0, longitude: -76.0)

      results = PublicFeed.paginate_feed(current_user, sort: 'newest', radius: 25)
      results.size.must_equal 2
      results[0].must_equal user2
      results[1].must_equal user1
    end

    it "must order by nearest" do
      current_user = FactoryGirl.create(:registered_user, :female, latitude: 39.9475787, longitude: -75.1564073)
      nearby_user = FactoryGirl.create(:registered_user, :female, latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, latitude: 40.0, longitude: -76.0)

      results = PublicFeed.paginate_feed(current_user, sort: 'nearest', latitude: 39.9475787, longitude: -75.1564073)
      results[0].must_equal current_user
      results[1].must_equal nearby_user
    end

    it "must order by nearest with explicit radius" do
      current_user = FactoryGirl.create(:registered_user, :female, latitude: 39.9475787, longitude: -75.1564073)
      nearby_user = FactoryGirl.create(:registered_user, :female, latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :female, latitude: 45.0, longitude: -78.0)

      results = PublicFeed.paginate_feed(current_user, sort: 'nearest', latitude: 39.9475787, longitude: -75.1564073, radius: 25)
      results.size.must_equal 3
      results[0].must_equal current_user
      results[1].must_equal nearby_user
    end

  end
end
