# frozen_string_literal: true

# In-process error tracker — dashboard at /uchujin.
#
# NOTE: these blocks run inside the engine's own controllers (not the host
# ApplicationController), so they read the session + ::User directly instead
# of the host's require_login/current_user helpers.
Uchujin.configure do |config|
  config.app_name = "Noshi"

  # Admin-only — mirrors require_admin in ApplicationController.
  config.authenticate do
    @_host_user ||= session[:user_id] && ::User.find_by(id: session[:user_id])
    unless @_host_user&.admin?
      redirect_to "/", alert: I18n.t("auth.login_required", default: "ログインが必要です")
    end
  end

  config.current_user_method { @_host_user ||= session[:user_id] && ::User.find_by(id: session[:user_id]) }

  # Capture in production only (development stays quiet unless you add it).
  config.environments = %w[production]

  # Bot/stale-session noise.
  config.ignored_exceptions << "ActionController::InvalidAuthenticityToken"
  # Crawlers request HTML-only pages with Accept: application/json. Rails already
  # answers 406 Not Acceptable (rescue_responses), so the response is correct —
  # only the report is noise.
  config.ignored_exceptions << "ActionController::UnknownFormat"
  # Malformed multipart bodies (scanners) are mapped to 400 via rescue_responses,
  # but that only changes the HTTP status — Uchujin still flags the raise itself.
  config.ignored_exceptions << "Rack::BadRequest"

  # NOTE: production ActionMailer has perform_deliveries = false, so alerts are
  # dormant until SMTP delivery is configured (see production.rb).
  config.notification_email = "cody@moab.jp"
  config.mailer_from = "Noshi <no-reply@noshi.moab.jp>"
  config.deploy_token = ENV["UCHUJIN_DEPLOY_TOKEN"]
  config.revision = ENV["GIT_REVISION"].presence || ENV["KAMAL_VERSION"]

  # MCP — AI agent triage at POST /uchujin/api/mcp
  # Prefer dedicated UCHUJIN_MCP_TOKEN; falls back to deploy_token if blank.
  config.mcp_enabled = ActiveModel::Type::Boolean.new.cast(
    ENV.fetch("UCHUJIN_MCP_ENABLED", Rails.env.production? ? "true" : "false")
  )
  config.mcp_token = ENV["UCHUJIN_MCP_TOKEN"]

  config.queue_name = :default
  config.pruning_enabled = true
  config.retention_period = 90.days
  config.resolved_retention_period = 30.days
end
