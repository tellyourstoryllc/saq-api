ChatApp::Application.routes.draw do
  scope via: :all do
    match '/users/create', to: 'users#create', as: 'create_user'
    match '/users/update', to: 'users#update', as: 'update_user'

    match '/login', to: 'sessions#create', as: 'login'

    match '/groups/create', to: 'groups#create', as: 'create_group'
    match '/join/:join_code', to: 'groups#join', as: 'join_group'
  end
end
