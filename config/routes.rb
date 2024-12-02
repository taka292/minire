Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }
  # devise_for :users
  get "home/index"
  root 'home#index'
  # get 'search', to: 'reviews#search'
end
