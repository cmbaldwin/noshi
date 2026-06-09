module Api
  module V1
    # The selectable gift occasions (表書き).
    class OmotegakiController < BaseController
      def index
        occasions = NoshiCatalog.occasions
        render json: { count: occasions.size, occasions: occasions }
      end
    end
  end
end
