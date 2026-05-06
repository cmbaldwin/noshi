require_relative "boot"

require "rails"
require "action_controller/railtie"
require "action_view/railtie"
require "active_model/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

Dotenv::Rails.load if %w[development test].include?(ENV["RAILS_ENV"])

module Noshiio
  class Application < Rails::Application
    config.load_defaults 8.0

    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}").to_s]
    config.i18n.available_locales = %i[ja en]
    config.i18n.enforce_available_locales = true
    config.i18n.fallbacks = [:en]

    config.eager_load_paths << Rails.root.join("lib")
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
  end
end
