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

  test "logout requires a CSRF token while the OAuth callback stays exempt" do
    # Forgery protection is off in the test env, so enable it the way the
    # framework reads it (app config + controller config) for this test only.
    Rails.application.config.action_controller.allow_forgery_protection = true
    SessionsController.allow_forgery_protection = true
    begin
      # GET callback has no token by design (it comes from Google) — still works.
      get "/auth/google_oauth2/callback"
      assert_redirected_to root_path

      # But a tokenless logout is rejected instead of clearing the session.
      delete logout_path
      assert_response :unprocessable_entity
    ensure
      Rails.application.config.action_controller.allow_forgery_protection = false
      SessionsController.allow_forgery_protection = false
    end
  end

  test "callback without an auth hash fails gracefully" do
    Rails.application.env_config.delete("omniauth.auth")
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    get "/auth/google_oauth2/callback"
    assert_redirected_to root_path
  end
end
