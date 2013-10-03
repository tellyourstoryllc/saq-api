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
  require File.expand_path("../../config/environment", __FILE__)
  require "rails/test_help"
  require "minitest/rails"
  require 'turn/autorun'

  #Turn.config.format = :progress

  # To add Capybara feature tests add `gem "minitest-rails-capybara"`
  # to the test group in the Gemfile and uncomment the following:
  # require "minitest/rails/capybara"

  # Uncomment for awesome colorful output
  # require "minitest/pride"

  class ActiveSupport::TestCase
    # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
    #fixtures :all

    # Add more helper methods to be used by all tests here...

    def result
      @result ||= JSON.load(response.body)
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end
