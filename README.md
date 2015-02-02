## Development

Install the Ruby version as specified in `.ruby-version` (to match production).
__________________________________________________

Copy all `config/[name].yml.sample` files to `config/[name].yml` and configure accordingly.
__________________________________________________

Create the dbs:

```shell
rake db:create
```
__________________________________________________

Update the db to *not* add all new columns as utf8mb4:

```sql
ALTER DATABASE saq_dev DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
```
__________________________________________________

Migrate db:

```shell
rake db:migrate
```
__________________________________________________

Install Redis (>= 2.8.17) if not already installed:

```shell
brew install redis
# Start redis-server however you like
```
__________________________________________________

Install gems:

```shell
bundle
```
__________________________________________________

Start server:

```shell
bundle exec unicorn -c config/unicorn.rb
```
__________________________________________________



## Add Static Data

Create mobile push apps:

```ruby
Rpush::Apns::App.create!(name: 'saq_ios', certificate: File.read('/path/to/apn_saq_prod.pem'), environment: 'production', connections: 5)
```
__________________________________________________

In nanny console:

```ruby
Client.new(name: 'saq').save
```

Copy the nanny client token to the "moderator.token" saq config.
__________________________________________________

Insert video_moderation_reject_reasons:

```sql
INSERT INTO video_moderation_reject_reasons (title, message_to_user, default_reason, created_at, updated_at) VALUES ('Default', "Sorry, your video was not approved.", 1, NOW(), NOW());
INSERT INTO video_moderation_reject_reasons (title, message_to_user, default_reason, created_at, updated_at) VALUES ('Too Dark', "Sorry, your video was not approved because we couldn't see you clearly. Please try again in a brighter location.", 0, NOW(), NOW());
INSERT INTO video_moderation_reject_reasons (title, message_to_user, default_reason, created_at, updated_at) VALUES ('Too Noisy', "Sorry, your video was not approved. There was too much background noise to hear you clearly. Please try again in a quiet location.", 0, NOW(), NOW());
```
__________________________________________________



## Tests

Copy dev db schema to test db:

```shell
rake db:test:prepare
```
__________________________________________________

Run the tests (Warning: make sure your `test` Redis config in `config/app.yml` is unused and different than `development`, as that Redis db will be cleared before each test):

```shell
rake
```
__________________________________________________

Or for fast tests, run spork in one tab:

```shell
RAILS_ENV=test spork
```

And in another tab:

```shell
testdrb test/**/*_test.rb
```
__________________________________________________


## Admin

To create an admin login, use the Sysop model and add permissions to it.

```ruby
s = Sysop.create(name: 'username', password: 'secret', password_confirmation: 'secret', email: 'email@address')
s.permissions << 'superuser'
```
__________________________________________________
