module Api
  module V1
    # Approved community background uploads, with their ratings. ?sort=new for
    # newest-first (default is top-rated).
    class BackgroundsController < BaseController
      def index
        scope = Background.approved.with_attached_image.includes(:user)
        scope = params[:sort] == "new" ? scope.newest : scope.top_rated
        backgrounds = scope.to_a

        render json: {
          count: backgrounds.size,
          backgrounds: backgrounds.map { |bg| background_json(bg) }
        }
      end
    end
  end
end
