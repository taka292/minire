Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions"
  }
  get "home/index"
  root "home#index"
  resources :reviews do
    resources :comments, only: [ :create ]
    resources :likes, only: [ :create, :destroy ]
  end

  get "likes", to: "likes#index", as: "liked_reviews"

  resources :profiles, only: [:show, :edit, :update] do
    member do
      get :reviews
      get :likes
    end
  end
end
