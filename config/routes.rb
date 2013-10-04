ChatApp::Application.routes.draw do
  resources :users
  get '/join/:join_code', to: 'groups#join', as: :join_group

  resources :groups
  post '/user/update', to: 'users#update', as: 'update_user'

  post '/login', to: 'sessions#create', as: 'login'
end
