class SessionsController < ApplicationController
  # Only the OAuth callback is exempt: it is a GET redirect from Google with
  # no CSRF token. Everything else here (notably logout) keeps the default
  # forgery protection. The request phase that starts the flow is
  # CSRF-protected by omniauth-rails_csrf_protection instead.
  skip_before_action :verify_authenticity_token, only: :create, raise: false

  def create
    auth = request.env["omniauth.auth"]
    user = auth && User.from_omniauth(auth)

    if user&.persisted?
      reset_session
      session[:user_id] = user.id
      redirect_to(stored_return_path || root_path, notice: t("auth.signed_in"))
    else
      redirect_to root_path, alert: t("auth.sign_in_failed")
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: t("auth.signed_out")
  end

  def failure
    redirect_to root_path, alert: t("auth.sign_in_failed")
  end

  private

  def stored_return_path
    session.delete(:return_to)
  end
end
