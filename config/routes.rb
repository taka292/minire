Rails.application.routes.draw do
  get "home/index"
  root 'home#index'
  # get 'search', to: 'reviews#search'
end
