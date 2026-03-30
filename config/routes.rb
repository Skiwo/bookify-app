Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#landing"
  get "about", to: "pages#about"
  get "privacy", to: "pages#privacy"

  passwordless_for :users, at: "/", as: :users

  resources :invitations, only: [:show], param: :token do
    member do
      post :accept
    end
  end

  get "callbacks/onboard", to: "callbacks#onboard", as: :callbacks_onboard
  get "callbacks/manage", to: "callbacks#manage", as: :callbacks_manage

  namespace :booker do
    get "dashboard", to: "dashboard#show"
    patch "dashboard/dismiss_welcome", to: "dashboard#dismiss_welcome", as: :dismiss_welcome
    resource :settings, only: [:show, :update]
    resources :freelancers, only: [:index, :new, :create, :show, :destroy] do
      member do
        post :sync
        post :resend_invite
      end
    end
    resources :bookings, only: [:index, :new, :create, :show, :edit, :update] do
      member do
        post :complete
        post :uncomplete
        post :pay
      end
    end
    resources :payouts, only: [:index, :show] do
      collection do
        post :sync_all
      end
    end
  end

  namespace :freelancer do
    get "dashboard", to: "dashboard#show"
    resource :profile, only: [:show]
    resources :bookings, only: [:index, :show]
  end
end
