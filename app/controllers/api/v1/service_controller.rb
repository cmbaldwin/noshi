module Api
  module V1
    # API entry point / discovery document. Linked from llms.txt so AI agents
    # can find and self-describe the service.
    class ServiceController < BaseController
      def show
        api = "#{site_base_url}/api/v1"
        render json: {
          name: "Noshi (熨斗) Generator API",
          description: "Build Japanese gift-envelope noshi (熨斗). This API exposes the " \
                       "occasions, designs, and community backgrounds, and composes a deep " \
                       "link to the in-browser editor where the print-ready JPEG is rendered " \
                       "and downloaded. Free to use, no account required.",
          version: "1",
          website: site_base_url,
          documentation: "#{site_base_url}/llms.txt",
          locales: %w[ja en],
          capabilities: {
            paper_sizes: NoshiCatalog::PAPER_SIZES,
            max_names: NoshiCatalog::MAX_NAMES,
            builtin_designs: NoshiCatalog::BUILTIN_DESIGN_COUNT,
            rendering: "client-side — the editor renders and downloads a print-ready JPEG in the browser"
          },
          endpoints: {
            service: api,
            occasions: "#{api}/omotegaki",
            designs: "#{api}/designs",
            backgrounds: "#{api}/backgrounds",
            compose: "#{api}/noshi?omotegaki={occasion}&names={name1,name2}&paper_size={B5|A4|縦B5|縦A4}&ntype={1-#{NoshiCatalog::BUILTIN_DESIGN_COUNT}}"
          }
        }
      end
    end
  end
end
