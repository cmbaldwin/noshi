Rails.application.routes.draw do
  scope "(/:locale)", locale: /en|ja/ do
    root "noshis#index"

    resources :noshis, only: %i[create]
    get "noshis/new(/:ntype/:names/:omotegaki)", as: :new_with_params, to: "noshis#new"
    get "about", to: "noshis#about"
    get "privacy", to: "noshis#privacy"
    get "terms", to: "noshis#terms"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
