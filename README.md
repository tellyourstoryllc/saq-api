## Development

Copy all `config/[name].yml.sample` files to `config/[name].yml` and configure accordingly.

Create the dbs:

    rake db:create

Update the db to *not* add all new columns as utf8mb4:

    ALTER DATABASE chat_app_dev DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;

Migrate db:

    rake db:migrate

Install Redis (>= 2.6.12) if not already installed:

    brew install redis
    # Start redis-server however you like

Install gems:

    bundle

Start server:

    bundle exec unicorn -c config/unicorn.rb


## Tests

Copy dev db schema to test db:

    rake db:test:prepare

Run the tests (Warning: make sure your `test` Redis config in `config/app.yml` is unused and different than `development`, as that Redis db will be cleared before each test):

    rake

Or for fast tests, run spork in one tab:

    spork

And in another tab:

    testdrb test/**/*_test.rb
