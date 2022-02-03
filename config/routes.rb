Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  get '/index', to: 'profiles#index'
  get '/profiles/:uuid', to: 'profiles#show'
 post '/profiles/:uuid', to: 'profiles#update'
  get '/profiles/:uuid/posts', to: 'profiles#posts'
  get '/statistics', to: 'profiles#statistics'
  get '/posts/:post_type/:post_id', to: 'posts#show'
  post '/update', to: 'application#update'
  root 'profiles#index'
end
