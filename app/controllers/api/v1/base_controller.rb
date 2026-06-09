module Api
  module V1
    # Public, read-only JSON API. No auth, CORS-open so AI agents and browsers
    # can call it. Inherits from ActionController::API (no cookies/CSRF/locale).
    class BaseController < ActionController::API
      before_action :set_cors_headers

      private

      def set_cors_headers
        headers["Access-Control-Allow-Origin"] = "*"
        headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
        headers["Access-Control-Allow-Headers"] = "Content-Type"
      end

      # Canonical public origin for building absolute URLs. Falls back to the
      # request origin so it works in any environment.
      def site_base_url
        ENV["SITE_BASE_URL"].presence || request.base_url
      end

      def asset_url(logical_path)
        path = ActionController::Base.helpers.asset_path(logical_path)
        path.start_with?("http") ? path : "#{site_base_url}#{path}"
      rescue StandardError
        nil
      end

      def blob_url(attachment)
        return nil unless attachment&.attached?

        Rails.application.routes.url_helpers.rails_blob_url(attachment, host: site_base_url)
      rescue StandardError
        nil
      end

      def background_json(background)
        {
          id: background.id,
          title: background.title,
          description: background.description,
          orientation: background.orientation,
          average_rating: background.average_rating,
          ratings_count: background.ratings_count,
          uploaded_by: background.user.display_name,
          image_url: blob_url(background.image)
        }
      end
    end
  end
end
