Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    confirmations: "users/confirmations",
    sessions: "users/sessions",
    passwords: "users/passwords",
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  root "home#index"
  resources :reviews do
    resources :comments, only: [ :create, :destroy, :edit, :update ]
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

  resources :items, only: [ :index, :show ]

  resources :notifications, only: [ :index ] do
    collection do
      post :update_checked
    end
  end

  resources :amazon, only: [ :index ]

  get "/terms_of_service", to: "static_pages#terms_of_service"
  get "/privacy_policy", to: "static_pages#privacy_policy"

  namespace :admin do
    resources :items, only: [ :index, :edit, :update, :destroy ] do
      post :fetch_amazon_info, on: :member
    end

    resources :categories do
      member do
        patch :move_higher
        patch :move_lower
      end
    end
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
