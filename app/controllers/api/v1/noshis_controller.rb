require "erb"

module Api
  module V1
    # Compose a noshi spec from query params and return a deep link to the
    # in-browser editor (where the print-ready JPEG is generated). The image is
    # rendered client-side, so the API returns a URL rather than an image.
    class NoshisController < BaseController
      def show
        names = parse_names(params[:names])
        omotegaki = params[:omotegaki].to_s.strip
        paper_size = NoshiCatalog::PAPER_SIZES.include?(params[:paper_size]) ? params[:paper_size] : "B5"
        ntype = clamp_ntype(params[:ntype])

        render json: {
          spec: {
            omotegaki: omotegaki,
            names: names,
            paper_size: paper_size,
            ntype: ntype,
            orientation: NoshiCatalog.orientation_for(ntype)
          },
          editor_url: editor_url(ntype, names, omotegaki),
          instructions: "Open editor_url in a browser to preview, fine-tune, and download " \
                        "the print-ready JPEG. Rendering happens client-side; no account is required.",
          download: "In the editor, press 作成 / Create to download the JPEG."
        }
      end

      private

      def parse_names(raw)
        Array(raw).flat_map { |v| v.to_s.split(/[,、\s]+/) }
                  .map(&:strip).reject(&:blank?).first(NoshiCatalog::MAX_NAMES)
      end

      def clamp_ntype(raw)
        n = raw.to_i
        n = 1 if n < 1
        [n, NoshiCatalog::BUILTIN_DESIGN_COUNT].min
      end

      # Deep link into the pre-fill route only when we have names + an occasion;
      # otherwise point at the empty editor.
      def editor_url(ntype, names, omotegaki)
        return site_base_url if names.empty? || omotegaki.blank?

        segments = [ntype, names.join(","), omotegaki].map { |s| ERB::Util.url_encode(s.to_s) }
        "#{site_base_url}/noshis/new/#{segments[0]}/#{segments[1]}/#{segments[2]}"
      end
    end
  end
end
