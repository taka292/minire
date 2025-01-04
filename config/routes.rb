Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    sessions: "users/sessions"
  }
  get "home/index"
  root "home#index"
  resources :reviews do
    resources :comments, only: [ :create ]
    resources :likes, only: [ :create, :destroy ]
  end

  resources :profiles, only: [ :show, :edit, :update ] do
    member do
      get :likes
      get :edit_email
      patch :update_email
      get :edit_password
      patch :update_password
    end
  end

  resources :items, only: [ :index, :show]

  namespace :admin do
    resources :items, only: [:index, :edit, :update]
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
