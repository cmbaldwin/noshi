class ApplicationController < ActionController::Base
  before_action :set_locale

  helper_method :current_user, :user_signed_in?

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] && User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end

  # Guard for actions that require an account. Remembers where the user was
  # headed so we can send them back after sign-in.
  def require_login
    return if user_signed_in?

    session[:return_to] = request.fullpath if request.get?
    redirect_to root_path, alert: t("auth.login_required")
  end

  def require_admin
    return if current_user&.admin?

    redirect_to root_path, alert: t("auth.login_required")
  end
end
