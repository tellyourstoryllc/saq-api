## Development

Copy all `config/[name].yml.sample` files to `config/[name].yml` and configure accordingly.

Set up the db:

    rake db:create
    rake db:migrate

Install Redis if not already installed:

    brew install redis
    # Start redis-server however you like

Install gems:

    bundle

Start server:

    bundle exec unicorn -c config/unicorn.rb


## Tests

Copy dev db schema to test db:

    rake db:test:prepare

Run the tests:

    rake

Or for fast tests, run spork in one tab:

    spork

And in another tab:

    testdrb test/**/*_test.rb
