source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.0"
gem "propshaft"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 2.7"

# Persistence + accounts layer (added for user registration, saved noshi, and
# community background uploads). The core generator still works without these,
# but accounts, saving, and uploads require a database and object storage.
gem "sqlite3", ">= 2.1"
gem "image_processing", "~> 1.2" # ActiveStorage variants (background thumbnails)

# Google OAuth sign-in
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# Billing for the paid image-storage tier
gem "stripe"

gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "markdown_for_agents", github: "cmbaldwin/markdown_for_agents", tag: "v0.1.1"
gem "thruster", require: false

gem "dotenv-rails", groups: %i[development test]

group :development do
  gem "rb-portless", require: "portless/rails"

  gem "kamal", require: false
  gem "web-console"
end

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end
