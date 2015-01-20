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
ALTER DATABASE knowme_dev DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
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

Install Elasticsearch:

```shell
brew install elasticsearch
# Start elasticsearch however you like
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

Import emoticons:

```ruby
Emoticon.reload
```
__________________________________________________

Create robot user:

```ruby
robot_username = 'teamknowme'; Robot.class_eval{ def self.username; 'foo' end }; Account.create!(registered: true, password: STDIN.noecho(&:gets).chomp, user_attributes: {username: robot_username}, emails_attributes: [{email: 'bot@know.me'}])
```
__________________________________________________

Create mobile push apps:

```ruby
Rpush::Apns::App.create!(name: 'knowme_ios', certificate: File.read('/path/to/apn_knowme_prod.pem'), environment: 'production', connections: 5)
```
__________________________________________________

Insert flag reasons:

```sql
INSERT INTO flag_reasons (`text`, moderate, created_at, updated_at) VALUES ('Nudity or sexual content', 1, NOW(), NOW());
INSERT INTO flag_reasons (`text`, moderate, created_at, updated_at) VALUES ('Offensive content', 0, NOW(), NOW());
```
__________________________________________________

In nanny console:

```ruby
Client.new(name: 'knowme').save
```

Copy the nanny client token to the "moderator.token" knowme config.
__________________________________________________


Create the one app-level index if it doesn't yet exist (# of shards can never be changed!), and set/update all models' field mappings.

Note: Run this every time one of the model's mappings change. When in doubt, run it.

```shell
bundle exec rake elasticsearch:configure
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
