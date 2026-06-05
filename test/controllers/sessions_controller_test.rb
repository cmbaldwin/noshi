require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: "google_oauth2",
      uid: "uid-abc",
      info: { email: "hana@example.com", name: "Hana", image: "https://img/h.png" }
    )
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
  end

  teardown { OmniAuth.config.test_mode = false }

  test "callback signs the user in and redirects" do
    assert_difference -> { User.count }, 1 do
      get "/auth/google_oauth2/callback"
    end
    assert_redirected_to root_path
    follow_redirect!
    assert_match "Hana", @response.body # name shown in nav once signed in
  end

  test "logout clears the session" do
    get "/auth/google_oauth2/callback"
    delete logout_path
    assert_redirected_to root_path
    follow_redirect!
    # Signed-out nav offers the Google sign-in button again.
    assert_match(/auth\/google_oauth2/, @response.body)
  end

  test "callback without an auth hash fails gracefully" do
    Rails.application.env_config.delete("omniauth.auth")
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    get "/auth/google_oauth2/callback"
    assert_redirected_to root_path
  end
end
