module Api
  module V1
    # Serves the OpenAPI 3.0.3 specification for the Noshi public API.
    # Machine-readable contract for AI agents, developer tooling, and client codegen.
    # GET /api/v1/openapi.json
    class OpenApiController < BaseController
      def show
        render json: build_spec
      end

      private

      def build_spec
        api_base = "#{site_base_url}/api/v1"

        {
          openapi: "3.0.3",
          info: {
            title: "Noshi (熨斗) Generator API",
            description: "A read-only, CORS-open, no-auth JSON API for the Noshi " \
                         "Japanese gift-envelope generator. AI agents can query occasions, " \
                         "designs, and community backgrounds, then compose a deep link to " \
                         "the in-browser editor where the print-ready JPEG is rendered and " \
                         "downloaded. Free to use — no account required.",
            version: "1",
            contact: { url: site_base_url },
            license: { name: "MIT" }
          },
          servers: [
            { url: api_base, description: "Production (noshi.moab.jp)" }
          ],
          paths: build_paths,
          components: build_components
        }
      end

      # rubocop:disable Metrics/MethodLength
      def build_paths
        {
          "/" => {
            get: {
              operationId: "getServiceInfo",
              summary: "Service manifest",
              description: "Returns API metadata: name, version, capabilities " \
                           "(paper sizes, max recipient names, design count), and a map " \
                           "of all endpoint URLs. Recommended first call for AI agents " \
                           "discovering the service.",
              tags: ["discovery"],
              responses: {
                "200" => {
                  description: "Service manifest",
                  content: {
                    "application/json" => {
                      schema: { "$ref" => "#/components/schemas/ServiceManifest" },
                      example: service_manifest_example
                    }
                  }
                }
              }
            }
          },
          "/omotegaki" => {
            get: {
              operationId: "listOccasions",
              summary: "List gift-occasion labels (表書き)",
              description: "Returns all selectable omotegaki (表書き) occasion labels, " \
                           "such as 御祝 (celebration), 御礼 (gratitude), 内祝 (return gift), " \
                           "御中元 (mid-year gift). Category separators are excluded. " \
                           "Pass the chosen label as the `omotegaki` query parameter to /noshi.",
              tags: ["catalog"],
              responses: {
                "200" => {
                  description: "Occasions list",
                  content: {
                    "application/json" => {
                      schema: { "$ref" => "#/components/schemas/OmotegakiList" }
                    }
                  }
                }
              }
            }
          },
          "/designs" => {
            get: {
              operationId: "listDesigns",
              summary: "List all available designs",
              description: "Returns the #{NoshiCatalog::BUILTIN_DESIGN_COUNT} built-in noshi " \
                           "background designs (ntype 1–#{NoshiCatalog::BUILTIN_DESIGN_COUNT}) " \
                           "plus any approved community uploads. Each entry includes `ntype` " \
                           "(pass to /noshi), `orientation` (landscape/portrait), and image URLs. " \
                           "Designs 1–#{NoshiCatalog::LANDSCAPE_DESIGN_COUNT} are landscape; " \
                           "#{NoshiCatalog::LANDSCAPE_DESIGN_COUNT + 1}–" \
                           "#{NoshiCatalog::BUILTIN_DESIGN_COUNT} are portrait.",
              tags: ["catalog"],
              responses: {
                "200" => {
                  description: "Design catalog",
                  content: {
                    "application/json" => {
                      schema: { "$ref" => "#/components/schemas/DesignCatalog" }
                    }
                  }
                }
              }
            }
          },
          "/backgrounds" => {
            get: {
              operationId: "listBackgrounds",
              summary: "List community-uploaded backgrounds",
              description: "Returns approved community background images with their star ratings " \
                           "(average and count).",
              tags: ["catalog"],
              parameters: [
                {
                  name: "sort",
                  in: "query",
                  description: 'Sort order. "top_rated" (default) or "new" for newest-first.',
                  required: false,
                  schema: {
                    type: "string",
                    enum: %w[top_rated new],
                    default: "top_rated"
                  }
                }
              ],
              responses: {
                "200" => {
                  description: "Background list",
                  content: {
                    "application/json" => {
                      schema: { "$ref" => "#/components/schemas/BackgroundList" }
                    }
                  }
                }
              }
            }
          },
          "/noshi" => {
            get: {
              operationId: "composeNoshi",
              summary: "Compose a noshi spec and editor URL",
              description: "Normalizes the provided parameters and returns a `spec` object plus " \
                           "an `editor_url` deep link. Open `editor_url` in a browser to " \
                           "preview, fine-tune, and download the print-ready JPEG. JPEG rendering " \
                           "happens entirely client-side — no account is required. " \
                           "All parameters are optional; omitting them opens the empty editor.",
              tags: ["compose"],
              parameters: [
                {
                  name: "omotegaki",
                  in: "query",
                  description: "Gift-occasion label (表書き), e.g. 御祝, 御礼, 内祝. " \
                               "Valid values come from /omotegaki.",
                  required: false,
                  schema: { type: "string", example: "御祝" }
                },
                {
                  name: "names",
                  in: "query",
                  description: "Comma-separated recipient name(s), " \
                               "up to #{NoshiCatalog::MAX_NAMES}. Japanese or English.",
                  required: false,
                  schema: { type: "string", example: "田中,鈴木" }
                },
                {
                  name: "paper_size",
                  in: "query",
                  description: "Paper size. Defaults to B5.",
                  required: false,
                  schema: {
                    type: "string",
                    enum: NoshiCatalog::PAPER_SIZES,
                    default: "B5"
                  }
                },
                {
                  name: "ntype",
                  in: "query",
                  description: "Design number (1–#{NoshiCatalog::BUILTIN_DESIGN_COUNT}). " \
                               "Use /designs to browse the catalog. " \
                               "Designs 1–#{NoshiCatalog::LANDSCAPE_DESIGN_COUNT} are landscape; " \
                               "#{NoshiCatalog::LANDSCAPE_DESIGN_COUNT + 1}–" \
                               "#{NoshiCatalog::BUILTIN_DESIGN_COUNT} are portrait.",
                  required: false,
                  schema: {
                    type: "integer",
                    minimum: 1,
                    maximum: NoshiCatalog::BUILTIN_DESIGN_COUNT,
                    example: 3
                  }
                }
              ],
              responses: {
                "200" => {
                  description: "Noshi spec and editor link",
                  content: {
                    "application/json" => {
                      schema: { "$ref" => "#/components/schemas/NoshiComposition" },
                      example: noshi_composition_example
                    }
                  }
                }
              }
            }
          }
        }
      end
      # rubocop:enable Metrics/MethodLength

      def build_components
        {
          schemas: {
            ServiceManifest: {
              type: "object",
              required: %w[name version capabilities endpoints],
              properties: {
                name: { type: "string", example: "Noshi (熨斗) Generator API" },
                description: { type: "string" },
                version: { type: "string", example: "1" },
                website: { type: "string", format: "uri" },
                documentation: { type: "string", format: "uri" },
                locales: { type: "array", items: { type: "string" }, example: %w[ja en] },
                capabilities: {
                  type: "object",
                  properties: {
                    paper_sizes: { type: "array", items: { type: "string" } },
                    max_names: { type: "integer", example: NoshiCatalog::MAX_NAMES },
                    builtin_designs: { type: "integer", example: NoshiCatalog::BUILTIN_DESIGN_COUNT },
                    rendering: { type: "string" }
                  }
                },
                endpoints: {
                  type: "object",
                  description: "Map of endpoint names to URL templates.",
                  additionalProperties: { type: "string" }
                }
              }
            },
            OmotegakiList: {
              type: "object",
              required: %w[count occasions],
              properties: {
                count: { type: "integer", description: "Number of selectable occasions" },
                occasions: {
                  type: "array",
                  items: { type: "string" },
                  description: "Selectable occasion labels (separators excluded)"
                }
              }
            },
            BuiltinDesign: {
              type: "object",
              required: %w[ntype orientation thumbnail_url image_url],
              properties: {
                ntype: {
                  type: "integer",
                  minimum: 1,
                  maximum: NoshiCatalog::BUILTIN_DESIGN_COUNT,
                  description: "Design number; pass to /noshi as the `ntype` parameter"
                },
                orientation: { type: "string", enum: %w[landscape portrait] },
                thumbnail_url: { type: "string", format: "uri" },
                image_url: { type: "string", format: "uri" }
              }
            },
            CommunityBackground: {
              type: "object",
              required: %w[id title orientation],
              properties: {
                id: { type: "integer" },
                title: { type: "string" },
                description: { type: "string", nullable: true },
                orientation: { type: "string", enum: %w[landscape portrait] },
                average_rating: { type: "number", format: "float", nullable: true },
                ratings_count: { type: "integer" },
                uploaded_by: { type: "string" },
                image_url: { type: "string", format: "uri", nullable: true }
              }
            },
            DesignCatalog: {
              type: "object",
              required: %w[builtin community],
              properties: {
                builtin: {
                  type: "array",
                  items: { "$ref" => "#/components/schemas/BuiltinDesign" }
                },
                community: {
                  type: "array",
                  items: { "$ref" => "#/components/schemas/CommunityBackground" }
                }
              }
            },
            BackgroundList: {
              type: "object",
              required: %w[count backgrounds],
              properties: {
                count: { type: "integer" },
                backgrounds: {
                  type: "array",
                  items: { "$ref" => "#/components/schemas/CommunityBackground" }
                }
              }
            },
            NoshiSpec: {
              type: "object",
              properties: {
                omotegaki: { type: "string", description: "Gift-occasion label" },
                names: { type: "array", items: { type: "string" } },
                paper_size: { type: "string", enum: NoshiCatalog::PAPER_SIZES },
                ntype: {
                  type: "integer",
                  minimum: 1,
                  maximum: NoshiCatalog::BUILTIN_DESIGN_COUNT
                },
                orientation: { type: "string", enum: %w[landscape portrait] }
              }
            },
            NoshiComposition: {
              type: "object",
              required: %w[spec editor_url instructions],
              properties: {
                spec: { "$ref" => "#/components/schemas/NoshiSpec" },
                editor_url: {
                  type: "string",
                  format: "uri",
                  description: "Deep link to the in-browser editor with parameters pre-filled"
                },
                instructions: {
                  type: "string",
                  description: "Human-readable instructions for using the editor"
                },
                download: { type: "string" }
              }
            }
          }
        }
      end

      def service_manifest_example
        {
          name: "Noshi (熨斗) Generator API",
          version: "1",
          capabilities: {
            paper_sizes: NoshiCatalog::PAPER_SIZES,
            max_names: NoshiCatalog::MAX_NAMES,
            builtin_designs: NoshiCatalog::BUILTIN_DESIGN_COUNT
          }
        }
      end

      def noshi_composition_example
        {
          spec: {
            omotegaki: "御祝",
            names: %w[田中 鈴木],
            paper_size: "A4",
            ntype: 3,
            orientation: "landscape"
          },
          editor_url: "#{site_base_url}/noshis/new/3/%E7%94%B0%E4%B8%AD%2C%E9%88%B4%E6%9C%A8/%E5%BE%A1%E7%A5%9D",
          instructions: "Open editor_url in a browser to preview, fine-tune, and download the print-ready JPEG.",
          download: "In the editor, press 作成 / Create to download the JPEG."
        }
      end
    end
  end
end
