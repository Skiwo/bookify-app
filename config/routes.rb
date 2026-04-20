Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

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

  # ─── Onboarding ─────────────────────────────────────────────────────────────
  get  "onboarding",          to: "onboarding#index", as: :onboarding
  namespace :onboarding do
    resource :shop, only: [:new, :create]
  end

  # ─── Bookify Marketplace ────────────────────────────────────────────────────

  # Public marketplace (no login required)
  get "shops",       to: "shops#index", as: :shops
  get "shops/:slug", to: "shops#show",  as: :shop
  post "shops/:slug/requests", to: "shop_requests#create", as: :shop_requests

  # Skill category pages (SEO)
  get "nb/no/:skill", to: "skill_pages#show", as: :skill_page

  # Shop owner cabinet
  namespace :shop_admin, path: "shop", as: "shop" do
    get "dashboard", to: "dashboard#show"
    resource :settings, only: [:show, :update] do
      member do
        post :pause
        post :close
        post :reopen
      end
    end
    resource :profile, only: [:show, :edit, :update]
    resources :members, only: [:index, :new, :create, :destroy]
    resources :jobs, only: [:index, :show] do
      member do
        post :issue_quote
        post :mark_complete
      end
    end
    resources :quotes, only: [:new, :create, :show]
  end

  # Client cabinet
  namespace :clients do
    get "dashboard", to: "dashboard#show"
    resource :registration, only: [:new, :create]
    resources :requests, only: [:index, :show]
    resources :quotes, only: [:index, :show] do
      member do
        post :accept
        post :decline
      end
    end
    resources :jobs, only: [:index, :show] do
      member do
        post :confirm
        post :dispute
      end
    end
  end

  # Three-party chat (accessible to all sides)
  resources :job_messages, only: [:create]

  # Roster member invitations
  resources :shop_member_invitations, only: [:show], param: :token do
    member do
      post :accept
    end
  end

  # Private shop invitations
  resources :shop_invitations, only: [:show], param: :token do
    member do
      post :accept
    end
  end
end
