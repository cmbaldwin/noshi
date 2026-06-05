Rails.application.routes.draw do
  # Auth lives outside the /:locale scope so the OAuth callback URL is stable.
  get  "auth/:provider/callback", to: "sessions#create"
  get  "auth/failure",            to: "sessions#failure"
  delete "logout",                to: "sessions#destroy", as: :logout

  scope "(/:locale)", locale: /en|ja/ do
    root "noshis#index"

    resources :noshis, only: %i[create]
    resources :saved_noshis, only: %i[index create destroy]
    get "noshis/new(/:ntype/:names/:omotegaki)", as: :new_with_params, to: "noshis#new"
    get "about", to: "noshis#about"
    get "privacy", to: "noshis#privacy"
    get "terms", to: "noshis#terms"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
