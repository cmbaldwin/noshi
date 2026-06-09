module Api
  module V1
    # Available noshi backgrounds: the built-in designs plus approved community
    # uploads. ntype is the value to pass to the compose endpoint / deep link.
    class DesignsController < BaseController
      def index
        builtin = (1..NoshiCatalog::BUILTIN_DESIGN_COUNT).map do |n|
          {
            ntype: n,
            orientation: NoshiCatalog.orientation_for(n),
            thumbnail_url: asset_url("noshi/thumbs/noshi#{n}-thumb.jpg"),
            image_url: asset_url("noshi/noshi#{n}.jpg")
          }
        end

        community = Background.approved.with_attached_image.top_rated.map { |bg| background_json(bg) }

        render json: { builtin: builtin, community: community }
      end
    end
  end
end
