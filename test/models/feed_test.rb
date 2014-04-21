require "test_helper"

describe Feed do
  describe "#feed_api" do
    after do
      User.destroy_all
    end

    it "must return the first page of feed users" do
      current_user = FactoryGirl.create(:registered_user, :male)
      deactivated_user = FactoryGirl.create(:registered_user, :male, :deactivated)
      6.times do
        FactoryGirl.create(:registered_user, :female)
      end

      results = Feed.feed_api(current_user, {})
      results.must_be :present?
      results.must_include current_user
      results.wont_include deactivated_user
    end

    it "must order by newest" do
      user1 = current_user = FactoryGirl.create(:registered_user, :male, created_at: 2.minutes.ago)
      user2 = FactoryGirl.create(:registered_user, :male, created_at: 1.minute.ago)
      6.times do
        FactoryGirl.create(:registered_user, :female)
      end

      results = Feed.feed_api(current_user, sort: 'newest')
      male_results = results.select {|u| u.gender == 'male' }
      male_results[0].must_equal user2
      male_results[1].must_equal user1
    end

    it "must order by newest with radius" do
      user1 = current_user = FactoryGirl.create(:registered_user, :male, created_at: 2.minutes.ago, latitude: 39.9475787, longitude: -75.1564073)
      user2 = FactoryGirl.create(:registered_user, :male, created_at: 1.minute.ago, latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :male, latitude: 40.0, longitude: -76.0)
      6.times do
        FactoryGirl.create(:registered_user, :female, latitude: 39.9475787, longitude: -75.1564073)
      end

      results = Feed.feed_api(current_user, sort: 'newest', radius: 25)
      male_results = results.select {|u| u.gender == 'male' }
      male_results.size.must_equal 2
      male_results[0].must_equal user2
      male_results[1].must_equal user1
    end

    it "must order by nearest" do
      current_user = FactoryGirl.create(:registered_user, :male, latitude: 39.9475787, longitude: -75.1564073)
      nearby_user = FactoryGirl.create(:registered_user, :male, latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :male, latitude: 40.0, longitude: -76.0)
      6.times do
        FactoryGirl.create(:registered_user, :female, latitude: 40.0, longitude: -76.0)
      end

      results = Feed.feed_api(current_user, sort: 'nearest', latitude: 39.9475787, longitude: -75.1564073)
      male_results = results.select {|u| u.gender == 'male' }
      male_results[0].must_equal current_user
      male_results[1].must_equal nearby_user
    end

    it "must order by nearest with explicit radius" do
      current_user = FactoryGirl.create(:registered_user, :male, latitude: 39.9475787, longitude: -75.1564073)
      nearby_user = FactoryGirl.create(:registered_user, :male, latitude: 39.7, longitude: -75.2)
      FactoryGirl.create(:registered_user, :male, latitude: 45.0, longitude: -78.0)
      6.times do
        FactoryGirl.create(:registered_user, :female, latitude: 45.0, longitude: -78.0)
      end

      results = Feed.feed_api(current_user, sort: 'nearest', latitude: 39.9475787, longitude: -75.1564073, radius: 25)
      male_results = results.select {|u| u.gender == 'male' }
      male_results.size.must_equal 3
      male_results[0].must_equal current_user
      male_results[1].must_equal nearby_user
    end

  end
end
