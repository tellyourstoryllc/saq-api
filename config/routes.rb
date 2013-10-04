ChatApp::Application.routes.draw do
  resources :users
  resources :groups

  get '/join/:join_code', to: 'groups#join', as: :join_group
  post '/user/update', to: 'users#update', as: 'update_user'
end
