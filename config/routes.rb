KrazyChat::Application.routes.draw do
  scope via: :all do
    match '/health_check' => 'monitor#health_check'
    match '/me', to: 'users#me', as: 'me'
    match '/users', to: 'users#index', as: 'users'
    match '/users/create', to: 'users#create', as: 'create_user'
    match '/users/update', to: 'users#update', as: 'update_user'
    match '/accounts/update', to: 'accounts#update', as: 'update_account'
    match '/password/reset_email' => 'accounts#send_reset_email', as: 'send_reset_email'
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

    match '/emails', to: 'emails#index', as: 'emails'
    match '/emails/create', to: 'emails#create', as: 'create_email'
    match '/emails/:id/update', to: 'emails#update', as: 'update_email'
    match '/emails/:id/destroy', to: 'emails#destroy', as: 'destroy_email'

    match '/phones/create', to: 'phones#create', as: 'create_phone'
    match '/phones/verify', to: 'phones#verify', as: 'verify_phone'

    match '/contacts', to: 'contacts#index', as: 'contacts'
    match '/contacts/add', to: 'contacts#add', as: 'add_contacts'
    match '/contacts/remove', to: 'contacts#remove', as: 'remove_contacts'
    match '/contacts/autoconnect', to: 'contacts#autoconnect', as: 'remove_autoconnect'
    match '/groups/:id/add_users', to: 'groups#add_users', as: 'groups_add_users'

    match '/hook/callback', to: 'hook#callback', as: 'hook_callback'

    match '/admin/sms_stats', to: 'admin#sms_stats', as: 'admin_sms_stats'
    match '/admin/cohort_metrics', to: 'admin#cohort_metrics', as: 'admin_cohort_metrics'
    match '/admin/users', to: 'admin#users', as: 'admin_users'
    match '/admin/users/:id', to: 'admin#show_user', as: 'admin_user'
    match '/logs/event', to: 'logs#event', as: 'logs_event'

    match '/snaps/fetched', to: 'snaps#fetched', as: 'fetched_snaps'
  end

  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == Rails.configuration.app['admin']['username'] &&
      password == Rails.configuration.app['admin']['password']
  end
end
