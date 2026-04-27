require "sidekiq/web"

Rails.application.routes.draw do
  # ─── Shared (both domains) ──────────────────────────────────────────────────

  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  passwordless_for :users, at: "/", as: :users

  resource :profile, only: [:edit, :update]
  resource :locale, only: [:update]

  resources :job_messages, only: [:create]
  resources :job_reads,    only: [:create]

  # Shop creation onboarding lives on bookify.app — shared so it works
  # from any domain during RC/staging
  get "onboarding", to: "onboarding#index", as: :onboarding
  namespace :onboarding do
    resource :shop, only: [:new, :create]
  end

  # Bookify × POP: enrollment redirect + callbacks.
  # Shared because the callback URL is generated from whatever domain
  # the user is on when they start POP enrollment.
  namespace :bookify do
    get "onboarding/shop",   to: "onboarding#shop",      as: :onboarding_shop
    get "onboarding/member", to: "onboarding#member",    as: :onboarding_member
    get "callbacks/shop",    to: "callbacks#shop_owner", as: :callback_shop
    get "callbacks/member",  to: "callbacks#member",     as: :callback_member
  end

  # Shop member invitations — shared because freelancers can be on any domain
  resources :shop_member_invitations, only: [:show], param: :token do
    member { post :accept }
  end

  # ─── bookify.app — client / demand surface ──────────────────────────────────

  constraints(BookifyDomainConstraint) do
    root "pages#landing"
    get "about",   to: "pages#about"
    get "privacy", to: "pages#privacy"

    get "shops",       to: redirect("/nb/no/shops"),     as: nil
    get "shops/:slug", to: redirect("/nb/no/a/%{slug}"), as: nil

    scope "/:lang/:country",
          defaults:    { lang: "nb", country: "no" },
          constraints: { lang: /[a-z]{2}/, country: /[a-z]{2}/ } do
      get  "shops",             to: "shops#index",          as: :shops
      get  "a/:slug",           to: "shops#show",           as: :shop
      post "a/:slug/requests",  to: "shop_requests#create", as: :shop_requests
      post "a/:slug/join",      to: "shop_joins#create",    as: :shop_join
      get  ":skill",            to: "skill_pages#show",     as: :skill_page
    end

    namespace :clients do
      get "dashboard", to: "dashboard#show"
      resource  :registration, only: [:new, :create]
      resource  :brreg_lookup, only: [:show]
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

    post "/requests", to: "multi_shop_requests#create", as: :multi_shop_requests

    resources :shop_invitations, only: [:show], param: :token do
      member { post :accept }
    end

    # Shop owner Bookify cabinet — on bookify.app, not payoutpartner.com
    namespace :shop_admin, path: "shop", as: "shop" do
      get "dashboard", to: "dashboard#show"
      resource :settings, only: [:show, :update] do
        member do
          post :pause
          post :close
          post :reopen
        end
      end
      resource  :profile, only: [:show, :edit, :update]
      resources :members, only: [:index, :new, :create, :destroy] do
        collection { post :invite }
        member     { post :resend }
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
  end

  # ─── payoutpartner.com — existing POP platform (legacy booker/freelancer flow) ─

  constraints(PopDomainConstraint) do
    get "/", to: redirect("/booker/dashboard"), as: :pop_root

    sidekiq_web = Rack::Builder.new do
      use Rack::Auth::Basic, "Sidekiq" do |user, password|
        expected_user     = ENV.fetch("SIDEKIQ_WEB_USER", "")
        expected_password = ENV.fetch("SIDEKIQ_WEB_PASSWORD", "")
        expected_user.present? &&
          ActiveSupport::SecurityUtils.secure_compare(user, expected_user) &&
          ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
      end
      run Sidekiq::Web
    end
    mount sidekiq_web, at: "/sidekiq"

    resources :invitations, only: [:show], param: :token do
      member { post :accept }
    end

    get "callbacks/onboard", to: "callbacks#onboard", as: :callbacks_onboard
    get "callbacks/manage",  to: "callbacks#manage",  as: :callbacks_manage

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
        collection { post :sync_all }
      end
    end

    namespace :freelancer do
      get "dashboard", to: "dashboard#show"
      resource  :profile, only: [:show]
      resources :bookings, only: [:index, :show]
      resources :jobs, only: [:show] do
        member do
          post :accept_assignment
          post :decline_assignment
          post :mark_complete
          post :sync_payout
        end
      end
    end

  end
end
