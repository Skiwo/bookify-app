Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  root "pages#landing"
  get "about", to: "pages#about"
  get "privacy", to: "pages#privacy"

  passwordless_for :users, at: "/", as: :users
  resource :profile, only: [:edit, :update]

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
    resources :jobs, only: [:show] do
      member do
        post :mark_complete
        post :sync_payout
      end
    end
  end

  # ─── Bookify × POP ──────────────────────────────────────────────────────────
  namespace :bookify do
    get "onboarding/shop",   to: "onboarding#shop",        as: :onboarding_shop
    get "onboarding/member", to: "onboarding#member",      as: :onboarding_member
    get "callbacks/shop",    to: "callbacks#shop_owner",   as: :callback_shop
    get "callbacks/member",  to: "callbacks#member",       as: :callback_member
  end

  # ─── Onboarding ─────────────────────────────────────────────────────────────
  get  "onboarding",          to: "onboarding#index", as: :onboarding
  namespace :onboarding do
    resource :shop, only: [:new, :create]
  end

  # ─── Bookify Marketplace ────────────────────────────────────────────────────

  # Legacy redirects (old URLs → new locale-scoped URLs)
  get "shops",       to: redirect("/nb/no/shops"), as: nil
  get "shops/:slug", to: redirect("/nb/no/a/%{slug}"), as: nil

  # Locale-scoped public marketplace (no login required)
  scope "/:lang/:country", defaults: { lang: "nb", country: "no" }, constraints: { lang: /[a-z]{2}/, country: /[a-z]{2}/ } do
    get "shops",        to: "shops#index",          as: :shops
    get "a/:slug",      to: "shops#show",           as: :shop
    post "a/:slug/requests", to: "shop_requests#create", as: :shop_requests
    post "a/:slug/join",     to: "shop_joins#create",    as: :shop_join
    get ":skill",       to: "skill_pages#show",     as: :skill_page
  end

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
    resources :members, only: [:index, :new, :create, :destroy] do
      collection do
        post :invite
      end
      member do
        post :resend
      end
    end
    resources :jobs, only: [:index, :show] do
      member do
        post :issue_quote
        post :mark_complete
        post :sync_payout
        post :respond_dispute
        post :resolve_dispute
      end
    end
    resources :quotes, only: [:new, :create, :show]
  end

  # Client cabinet
  namespace :clients do
    get "dashboard", to: "dashboard#show"
    resource :registration, only: [:new, :create]
    resource :brreg_lookup, only: [:show]
    resources :requests, only: [:index, :show]
    resources :quotes, only: [:index, :show] do
      member do
        post :accept
        post :decline
      end
    end
    resources :jobs, only: [:index, :show] do
      member do
        post :mark_complete
        post :dispute
        post :cancel
      end
    end
  end

  # Three-party chat (accessible to all sides)
  resources :job_messages, only: [:create]
  resources :job_reads, only: [:create]

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
