class FacebookUser
  include Redis::Objects

  attr_accessor :id
  value :profile
  set :friend_uids


  def initialize(attributes = {})
    attributes.each do |k,v|
      v = nil if v.blank?
      send("#{k}=", v)
    end
  end

  def fetch_friends
    if Settings.enabled?(:queue)
      FacebookFriendsWorker.perform_async(id)
    else
      fetch_friends!
    end
  end

  def fetch_friends!
    graph = Koala::Facebook::API.new(Rails.configuration.app['facebook']['app_access_token'])
    friends = graph.get_connections(id, 'friends')

    friends.each do |friend_hash|
      friend_uid = friend_hash['id']

      # Set the Facebook id and name if it doesn't yet exist
      # and make each other friends
      redis.multi do
        redis.set("facebook_user:#{friend_uid}:profile", friend_hash.to_json, {nx: true})
        redis.sadd(friend_uids.key, friend_uid)
        redis.sadd("facebook_user:#{friend_uid}:friend_uids", id)
      end
    end
  end

  def fetch_profile
    return if redis.exists(profile.key)

    if Settings.enabled?(:queue)
      FacebookProfileWorker.perform_async(id)
    else
      fetch_profile!
    end
  end

  def fetch_profile!
    graph = Koala::Facebook::API.new(Rails.configuration.app['facebook']['app_access_token'])
    self.profile = graph.get_object(id).to_json
  end
end
