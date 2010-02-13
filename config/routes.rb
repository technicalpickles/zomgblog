Zomgblog::Application.routes.draw do |map|
  resources :posts

  root :to => "posts#index"
end
