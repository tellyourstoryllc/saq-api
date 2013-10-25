ChatApp::Application.routes.draw do
  scope via: :all do
    match '/users/create', to: 'users#create', as: 'create_user'
    match '/users/update', to: 'users#update', as: 'update_user'

    match '/login', to: 'sessions#create', as: 'login'
    match '/checkin', to: 'checkin#index', as: 'checkin'

    match '/groups/create', to: 'groups#create', as: 'create_group'
    match '/groups/:id/update', to: 'groups#update', as: 'update_group'
    match '/groups/join/:join_code', to: 'groups#join', as: 'join_group'
    #match '/join/:join_code', to: 'groups#join', as: 'join_group'

    match '/groups/:group_id/messages/create', to: 'messages#create', as: 'create_message'
    match '/groups/:group_id/messages', to: 'messages#index', as: 'group_messages'

    match '/groups', to: 'groups#index', as: 'groups'
    match '/groups/:id', to: 'groups#show', as: 'show_group'
    match '/groups/:id/is_member', to: 'groups#is_member', as: 'is_member_group'

    match '/messages/:id/like', to: 'message_likes#create', as: 'like_message'
    match '/messages/:id/unlike', to: 'message_likes#destroy', as: 'unlike_message'
  end
end
