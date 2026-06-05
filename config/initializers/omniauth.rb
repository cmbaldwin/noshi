# Google OAuth sign-in. Credentials come from env (see config/deploy.yml +
# .kamal/secrets in production, .env in development).
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV["GOOGLE_CLIENT_ID"],
           ENV["GOOGLE_CLIENT_SECRET"],
           {
             scope: "email,profile",
             prompt: "select_account",
             access_type: "online",
             # Redirect URI is locale-independent (auth routes live outside the
             # /:locale scope) so a single callback URL works for ja and en.
             callback_path: "/auth/google_oauth2/callback"
           }
end

# The request phase must be POST (CSRF-protected by omniauth-rails_csrf_protection).
OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.silence_get_warning = true

# Don't blow up the whole request on a provider error; route to our failure
# handler instead.
OmniAuth.config.on_failure = proc do |env|
  SessionsController.action(:failure).call(env)
end
