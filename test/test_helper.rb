require 'rubygems'
require 'spork'
#uncomment the following line to use spork with the debugger
#require 'spork/ext/ruby-debug'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.

  $LOAD_PATH << "test"
  ENV["RAILS_ENV"] = "test"
  Rails.env = 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require "rails/test_help"
  require "minitest/rails"
  require "turn/autorun"
  require "factory_girl_rails"
  require "webmock/minitest"

  #Turn.config.format = :progress

  class ActiveSupport::TestCase
    # Add more helper methods to be used by all tests here...

    def setup
      raise("Rails.env == #{Rails.env}, i.e. Spork is a piece of shit") unless Rails.env == 'test'

      # Delete all test Redis keys before each test
      keys = Redis.current.keys
      Redis.current.del(keys) if keys.present?

      set_up_robot

      stub_request(:any, Rails.configuration.app['faye']['url'])
      stub_request(:any, /.*mixpanel.com/)
      stub_request(:any, /.*facebook.com/)

      FactoryGirl.create(:snap_invite_ad)
    end

    def set_up_robot
      Robot.instance_variable_set(:@user, nil)
      robot = User.create!(created_at: 10.years.ago)
      FactoryGirl.create(:account, registered: true, user_id: robot.id, created_at: 10.years.ago)
      User.where(id: robot.id).update_all(username: Robot.username)
    end

    def result
      @result ||= JSON.load(response.body)
    end

    def current_user
      @current_user ||= FactoryGirl.create(:registered_user)
    end

    def hash_must_include(actual, expected)
      (expected.to_a - actual.to_a).must_be_empty
    end

    def result_must_include(object_type, object_id, expected)
      actual = result.detect{ |obj| obj['object_type'] == object_type && obj['id'] == object_id }
      hash_must_include actual, expected
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end
