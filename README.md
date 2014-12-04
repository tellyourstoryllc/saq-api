## Development

Install the Ruby version as specified in `.ruby-version` (to match production).

Copy all `config/[name].yml.sample` files to `config/[name].yml` and configure accordingly.

Create the dbs:

```shell
rake db:create
```

Update the db to *not* add all new columns as utf8mb4:

```sql
ALTER DATABASE chat_app_dev DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
```

Migrate db:

```shell
rake db:migrate
```

Install Redis (>= 2.6.12) if not already installed:

```shell
brew install redis
# Start redis-server however you like
```

Install gems:

```shell
bundle
```

Start server:

```shell
bundle exec unicorn -c config/unicorn.rb
```


## Tests

Copy dev db schema to test db:

```shell
rake db:test:prepare
```

Run the tests (Warning: make sure your `test` Redis config in `config/app.yml` is unused and different than `development`, as that Redis db will be cleared before each test):

```shell
rake
```

Or for fast tests, run spork in one tab:

```shell
RAILS_ENV=test spork
```

And in another tab:

```shell
testdrb test/**/*_test.rb
```

## Admin

To create an admin login, use the Sysop model and add permissions to it.

```ruby
s = Sysop.create(name: 'username', password: 'secret', password_confirmation: 'secret', email: 'email@address')
s.permissions << 'superuser'
```
