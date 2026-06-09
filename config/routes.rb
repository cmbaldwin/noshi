Rails.application.routes.draw do
  # Auth lives outside the /:locale scope so the OAuth callback URL is stable.
  get  "auth/:provider/callback", to: "sessions#create"
  get  "auth/failure",            to: "sessions#failure"
  delete "logout",                to: "sessions#destroy", as: :logout

  # Stripe posts here server-to-server; keep it locale-independent.
  post "stripe/webhook", to: "billing#webhook"

  # Public, locale-independent JSON API for AI agents and integrations.
  namespace :api do
    namespace :v1 do
      get "/",           to: "service#show"
      get "omotegaki",   to: "omotegaki#index"
      get "designs",     to: "designs#index"
      get "backgrounds", to: "backgrounds#index"
      get "noshi",       to: "noshis#show"
    end
  end

  scope "(/:locale)", locale: /en|ja/ do
    root "noshis#index"

    resources :noshis, only: %i[create]
    resources :saved_noshis, only: %i[index create destroy]

    get  "billing",          to: "billing#show",     as: :billing
    post "billing/checkout", to: "billing#checkout", as: :billing_checkout
    post "billing/portal",   to: "billing#portal",   as: :billing_portal

    resources :backgrounds, only: %i[index new create destroy] do
      member { post :rate }
      collection { get :mine }
    end

    namespace :admin do
      resources :backgrounds, only: %i[index update]
    end
    get "noshis/new(/:ntype/:names/:omotegaki)", as: :new_with_params, to: "noshis#new"
    get "about", to: "noshis#about"
    get "privacy", to: "noshis#privacy"
    get "terms", to: "noshis#terms"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
