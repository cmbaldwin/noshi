source "https://rubygems.org"

ruby file: ".ruby-version"

gem "rails", "~> 8.0"
gem "propshaft"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 2.7"

gem "tzinfo-data", platforms: %i[windows jruby]
gem "bootsnap", require: false
gem "thruster", require: false

gem "dotenv-rails", groups: %i[development test]

group :development do
  gem "kamal", require: false
  gem "web-console"
end

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
end
