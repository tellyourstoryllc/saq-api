ChatApp::Application.routes.draw do
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
    match '/ios_device_preferences/update', to: 'ios_device_preferences#update', as: 'update_ios_device_preferences'
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

    match '/one_to_ones/:id', to: 'one_to_ones#show', as: 'one_to_one'
    match '/one_to_ones/:one_to_one_id/messages/create', to: 'one_to_one_messages#create', as: 'create_one_to_one_message'
    match '/one_to_ones/:one_to_one_id/messages', to: 'one_to_one_messages#index', as: 'one_to_one_messages'

    match '/messages/:id/likes', to: 'message_likes#index', as: 'message_likes'
    match '/messages/:id/like', to: 'message_likes#create', as: 'like_message'
    match '/messages/:id/unlike', to: 'message_likes#destroy', as: 'unlike_message'

    match '/faye_clients/:id/update', to: 'faye_clients#update', as: 'update_faye_client'

    match '/ios/apn/set', to: 'ios/apn#set', as: 'set_apn'
    match '/ios/apn/reset', to: 'ios/apn#reset', as: 'reset_apn'

    match '/blocked_users', to: 'blocked_users#index', as: 'blocked_users'
    match '/users/:id/block', to: 'blocked_users#create', as: 'block_user'
    match '/users/:id/unblock', to: 'blocked_users#destroy', as: 'unblock_user'
  end

  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'

  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    username == Rails.configuration.app['admin']['username'] &&
      password == Rails.configuration.app['admin']['password']
  end
end
