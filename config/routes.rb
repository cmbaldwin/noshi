# frozen_string_literal: true

# require 'sidekiq/web'

Rails.application.routes.draw do
  # Set up i18n routing
  scope '/:locale', locale: /en|ja/ do
    # Root to Noshis index
    root 'noshis#index'

    # Noshi routes
    resources :noshis do
      collection do
        delete 'destroy_multiple'
      end
    end
    get 'noshis/new/(:ntype/:namae/:omotegaki)', as: :new_with_params, to: 'noshis#new'
    get 'about', to: 'noshis#about'

    # # Devise routes
    # devise_scope :user do
    #   # Redirests signing out users back to sign-in
    #   get 'users', to: 'devise/sessions#new'
    # end
    # devise_for :users, controllers: {
    #   sessions: 'users/sessions'
    # }
  end

  # Redirects path with locale if no locale is specified
  root to: redirect("/#{I18n.default_locale}", status: 302), as: :redirected_root
  get '/*path', to: redirect("/#{I18n.default_locale}/%<path>s", status: 302), constraints: lambda { |req|
    !req.path.start_with?('/noshi/') && !req.path.start_with?('/ja/noshi/') && !req.path.start_with?('/en/noshi/')
  }

  # Sidekiq Web UI (with devise)
  # authenticate :user, ->(user) { user.id == 1 } do
  #   mount Sidekiq::Web => '/sidekiq'
  # end
end
