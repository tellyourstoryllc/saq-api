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
  require "turn/autorun"
  require "factory_girl_rails"

  #Turn.config.format = :progress

  FactoryGirl.sequences.clear
  FactoryGirl.factories.clear

  # Uncomment for awesome colorful output
  # require "minitest/pride"

  class ActiveSupport::TestCase
    # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
    #fixtures :all

    # Add more helper methods to be used by all tests here...

    def result
      @result ||= JSON.load(response.body)
    end

    def current_user
      @current_user ||= FactoryGirl.create(:user)
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.

end
