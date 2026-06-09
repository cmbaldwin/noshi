ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
  end
end

module SignInHelper
  # Establish a real session by driving the OAuth callback in test mode.
  def sign_in_as(user)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: user.provider,
      uid: user.uid,
      info: { email: user.email, name: user.name, image: user.avatar_url }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
    get "/auth/google_oauth2/callback"
  end

  def create_user(attrs = {})
    User.create!({ provider: "google_oauth2", uid: "uid-#{SecureRandom.hex(4)}",
                   email: "u#{SecureRandom.hex(2)}@example.com", name: "Test User" }.merge(attrs))
  end
end

class ActionDispatch::IntegrationTest
  include SignInHelper
end
