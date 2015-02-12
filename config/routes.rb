KrazyChat::Application.routes.draw do
  scope via: :all do
    match '/health_check' => 'monitor#health_check'
    match '/me', to: 'users#me', as: 'me'
    match '/users', to: 'users#index', as: 'users'
    match '/users/username_status', to: 'users#username_status', as: 'check_username_status'
    match '/users/create_unregistered', to: 'users#create_unregistered', as: 'create_unregistered_user'
    match '/users/create', to: 'users#create', as: 'create_user'
    match '/users/update', to: 'users#update', as: 'update_user'
    match '/accounts/update', to: 'accounts#update', as: 'update_account'
    match '/password/reset_email' => 'accounts#send_reset_email', as: 'send_reset_email'
    match '/password/reset_sms' => 'accounts#send_reset_sms', as: 'send_reset_sms'
    match '/password/reset/:token' => 'accounts#reset_password', :as => 'reset_password'

    match '/preferences/update', to: 'user_preferences#update', as: 'update_user_preferences'
    match '/ios_device_preferences/update', to: 'device_preferences#update', as: 'update_ios_device_preferences'
    match '/android_device_preferences/update', to: 'device_preferences#update', as: 'update_android_device_preferences'
    match '/groups/:group_id/user_group_preferences', to: 'user_group_preferences#show', as: 'show_user_group_preferences'
    match '/groups/:group_id/user_group_preferences/update', to: 'user_group_preferences#update', as: 'update_user_group_preferences'

    match '/login', to: 'sessions#create', as: 'login'
    match '/logout', to: 'sessions#destroy', as: 'logout'
    match '/checkin', to: 'checkin#index', as: 'checkin'

    match '/conversations', to: 'conversations#index', as: 'conversations'

    match '/groups/create', to: 'groups#create', as: 'create_group'
    match '/groups/:id/update', to: 'groups#update', as: 'update_group'
    match '/groups/join/:join_code', to: 'groups#join', as: 'join_group'
    match '/groups/:id/leave', to: 'groups#leave', as: 'leave_group'

    match '/groups/:group_id/messages/create', to: 'group_messages#create', as: 'create_group_message'
    match '/groups/:group_id/messages', to: 'group_messages#index', as: 'group_messages'

    match '/groups/find', to: 'groups#find', as: 'find_group'
    match '/groups/:id', to: 'groups#show', as: 'show_group'
    match '/groups/:id/is_member', to: 'groups#is_member', as: 'is_member_group'

    match '/groups/:id/banned_users', to: 'banned_group_users#index', as: 'banned_group_users'
    match '/groups/:id/ban', to: 'banned_group_users#create', as: 'ban_group_user'
    match '/groups/:id/unban', to: 'banned_group_users#destroy', as: 'unban_group_user'

    match '/one_to_ones/:id', to: 'one_to_ones#show', as: 'one_to_one'
    match '/one_to_ones/:id/update', to: 'one_to_ones#update', as: 'update_one_to_one'
    match '/one_to_ones/:one_to_one_id/messages/create', to: 'one_to_one_messages#create', as: 'create_one_to_one_message'
    match '/one_to_ones/:one_to_one_id/messages', to: 'one_to_one_messages#index', as: 'one_to_one_messages'

    match '/messages/create', to: 'messages#create', as: 'create_message'
    match '/messages/:id/delete', to: 'messages#delete', as: 'delete_message'
    match '/messages/:id/export', to: 'messages#export', as: 'export_message'

    match '/messages/:id/likes', to: 'message_likes#index', as: 'message_likes'
    match '/messages/:id/like', to: 'message_likes#create', as: 'like_message'
    match '/messages/:id/unlike', to: 'message_likes#destroy', as: 'unlike_message'

    match '/faye_clients/:id/update', to: 'faye_clients#update', as: 'update_faye_client'

    match '/ios/apn/set', to: 'ios/apn#set', as: 'set_apn'
    match '/ios/apn/reset', to: 'ios/apn#reset', as: 'reset_apn'

    match '/android/gcm/set', to: 'android/gcm#set', as: 'set_gcm'
    match '/android/gcm/reset', to: 'android/gcm#reset', as: 'reset_gcm'

    match '/blocked_users', to: 'blocked_users#index', as: 'blocked_users'
    match '/users/:id/block', to: 'blocked_users#create', as: 'block_user'
    match '/users/:id/unblock', to: 'blocked_users#destroy', as: 'unblock_user'
    match '/users/:id/avatar_image/flag', to: 'user_avatar_images#flag', as: 'flag_avatar_image'
    match '/users/:id/avatar_video/flag', to: 'user_avatar_videos#flag', as: 'flag_avatar_video'
    match '/users/:id/flag', to: 'users#flag', as: 'flag_user'

    match '/emails', to: 'emails#index', as: 'emails'
    match '/emails/create', to: 'emails#create', as: 'create_email'
    match '/emails/:id/update', to: 'emails#update', as: 'update_email'
    match '/emails/:id/destroy', to: 'emails#destroy', as: 'destroy_email'

    match '/phones/create', to: 'phones#create', as: 'create_phone'
    match '/phones/verify', to: 'phones#verify', as: 'verify_phone'
    match '/phones/add', to: 'phones#add', as: 'add_phones'
    match '/phones/confirm_activation', to: 'phones#confirm_activation', as: 'confirm_phone_activation'

    match '/contacts', to: 'contacts#index', as: 'contacts'
    match '/contacts/add', to: 'contacts#add', as: 'add_contacts'
    match '/contacts/remove', to: 'contacts#remove', as: 'remove_contacts'
    match '/contacts/autoconnect', to: 'contacts#autoconnect', as: 'remove_autoconnect'
    match '/groups/:id/add_users', to: 'groups#add_users', as: 'groups_add_users'

    match '/moderation/callback', to: 'moderation#callback', as: 'moderation_callback'

    match '/hook/callback', to: 'hook#callback', as: 'hook_callback'

    match '/admin', to: 'admin#app_reviews', as: 'admin'
    match '/admin/login', to: 'admin_auth#login', as: 'admin_login'
    match '/admin/logout', to: 'admin_auth#logout', as: 'admin_logout'
    match '/admin/forgot_password', to: 'admin_auth#forgot_password', as: 'admin_forgot_password'
    match '/admin/send_reset_password_email', to: 'admin_auth#send_reset_password_email', as: 'admin_send_reset_password_email'
    match '/admin/reset_password', to: 'admin_auth#update_password', as: 'admin_update_password', via: [:post, :put]
    match '/admin/reset_password', to: 'admin_auth#reset_password', as: 'admin_reset_password'
    match '/admin/sms_stats', to: 'admin#sms_stats', as: 'admin_sms_stats'
    match '/admin/cohort_metrics', to: 'admin#cohort_metrics', as: 'admin_cohort_metrics'
    match '/admin/users', to: 'admin#users', as: 'admin_users'
    match '/admin/users/:id', to: 'admin#show_user', as: 'admin_user'
    match '/admin/users/:id/friends', to: 'admin#show_user_friends', as: 'admin_user_friends'
    match '/admin/settings', to: 'admin#settings', as: 'admin_settings'
    match '/admin/settings/:key/edit', to: 'admin#edit_setting', as: 'admin_edit_setting'
    match '/admin/settings/:key/update', to: 'admin#update_setting', as: 'admin_update_setting'
    match '/admin/app_reviews', to: 'admin#app_reviews', as: 'admin_app_reviews'
    match '/admin/bot_messages', to: 'admin#bot_messages', as: 'admin_bot_messages'
    match '/admin/users/:id/ban', to: 'admin#ban_user', as: 'admin_ban_user'
    match '/admin/users/:id/unban', to: 'admin#unban_user', as: 'admin_unban_user'

    match '/logs/event', to: 'logs#event', as: 'logs_event'

    match '/snaps/fetched', to: 'snaps#fetched', as: 'fetched_snaps'

    match '/stories/search', to: 'stories#search', as: 'search_stories'
    match '/public_feed', to: 'public_feed#index', as: 'public_feed'
    match '/friend_feed', to: 'friend_feed#index', as: 'friend_feed'
    match '/stories/tags/:tag', to: 'stories#tagged', as: 'tagged_stories'
    match '/users/:id/stories', to: 'stories_lists#show', as: 'stories_list'
    match '/stories/:id', to: 'stories#show', as: 'show_story'
    match '/stories/:id/update', to: 'stories#update', as: 'update_story'
    match '/stories/:id/likes', to: 'story_likes#index', as: 'story_likes'
    match '/stories/:id/like', to: 'story_likes#create', as: 'like_story'
    match '/stories/:id/export', to: 'stories#export', as: 'export_story'
    match '/stories/:id/delete', to: 'stories#delete', as: 'delete_story'
    match '/stories/:id/flag', to: 'stories#flag', as: 'flag_story'

    match '/friends', to: 'friends#index', as: 'friends'
    match '/friends/add', to: 'friends#add', as: 'add_friends'
    match '/friends/remove', to: 'friends#remove', as: 'remove_friends'

    match '/blacklisted_usernames/add', to: 'blacklisted_usernames#add', as: 'add_blacklisted_username'
    match '/app_reviews/create', to: 'app_reviews#create', as: 'create_app_review'
  end

  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == Rails.configuration.app['admin']['username'] &&
      password == Rails.configuration.app['admin']['password']
  end
end
