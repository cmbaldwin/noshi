require "test_helper"

class Api::V1::ApiTest < ActionDispatch::IntegrationTest
  def json
    JSON.parse(@response.body)
  end

  test "service manifest lists endpoints and capabilities" do
    get "/api/v1"
    assert_response :success
    assert_equal "application/json", @response.media_type
    assert_equal "*", @response.headers["Access-Control-Allow-Origin"]
    assert_equal NoshiCatalog::PAPER_SIZES, json.dig("capabilities", "paper_sizes")
    assert json.dig("endpoints", "compose").present?
  end

  test "omotegaki endpoint returns selectable occasions without separators" do
    get "/api/v1/omotegaki"
    assert_response :success
    occasions = json["occasions"]
    assert_includes occasions, "御祝"
    assert_not(occasions.any? { |o| o.start_with?("┣") })
    assert_equal occasions.size, json["count"]
  end

  test "designs endpoint returns built-ins and approved community uploads" do
    user = User.create!(provider: "google_oauth2", uid: "api1", email: "api@x.com")
    bg = user.backgrounds.build(title: "Community", orientation: "portrait", status: "approved")
    bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                    filename: "sample.png", content_type: "image/png")
    bg.save!

    get "/api/v1/designs"
    assert_response :success
    assert_equal NoshiCatalog::BUILTIN_DESIGN_COUNT, json["builtin"].size
    assert_equal "landscape", json["builtin"].first["orientation"]
    assert_equal "Community", json["community"].first["title"]
  end

  test "backgrounds endpoint lists only approved uploads" do    user = User.create!(provider: "google_oauth2", uid: "api2", email: "api2@x.com")
    %w[approved pending].each do |status|
      bg = user.backgrounds.build(title: "BG-#{status}", orientation: "landscape", status: status)
      bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                      filename: "sample.png", content_type: "image/png")
      bg.save!
    end

    get "/api/v1/backgrounds"
    assert_response :success
    titles = json["backgrounds"].map { |b| b["title"] }
    assert_includes titles, "BG-approved"
    assert_not_includes titles, "BG-pending"
  end

  test "compose endpoint normalizes input and builds a deep link" do
    get "/api/v1/noshi", params: { omotegaki: "御祝", names: "田中, 鈴木", paper_size: "A4", ntype: "3" }
    assert_response :success
    assert_equal "御祝", json.dig("spec", "omotegaki")
    assert_equal %w[田中 鈴木], json.dig("spec", "names")
    assert_equal "A4", json.dig("spec", "paper_size")
    assert_includes json["editor_url"], "/noshis/new/3/"
  end

  test "compose clamps ntype and caps names, defaults paper size" do
    get "/api/v1/noshi", params: { omotegaki: "御礼", names: "a b c d e f g", paper_size: "bogus", ntype: "999" }
    assert_response :success
    assert_equal NoshiCatalog::BUILTIN_DESIGN_COUNT, json.dig("spec", "ntype")
    assert_equal NoshiCatalog::MAX_NAMES, json.dig("spec", "names").size
    assert_equal "B5", json.dig("spec", "paper_size")
  end

  test "compose with no names points at the editor root" do
    get "/api/v1/noshi"
    assert_response :success
    assert_not_includes json["editor_url"], "/noshis/new/"
  end

  # ── OpenAPI spec ────────────────────────────────────────────────────────────

  test "openapi.json returns a valid OpenAPI 3.0.3 document" do
    get "/api/v1/openapi.json"
    assert_response :success
    assert_equal "application/json", @response.media_type
    assert_equal "*", @response.headers["Access-Control-Allow-Origin"]
    assert_equal "3.0.3", json["openapi"]
    assert_equal "1", json.dig("info", "version")
    assert json.dig("info", "title").present?
  end

  test "openapi.json paths cover all five endpoints" do
    get "/api/v1/openapi.json"
    assert_response :success
    paths = json["paths"].keys
    assert_includes paths, "/"
    assert_includes paths, "/omotegaki"
    assert_includes paths, "/designs"
    assert_includes paths, "/backgrounds"
    assert_includes paths, "/noshi"
  end

  test "openapi.json components define all expected schemas" do
    get "/api/v1/openapi.json"
    assert_response :success
    schemas = json.dig("components", "schemas").keys
    assert_includes schemas, "ServiceManifest"
    assert_includes schemas, "OmotegakiList"
    assert_includes schemas, "DesignCatalog"
    assert_includes schemas, "BackgroundList"
    assert_includes schemas, "NoshiComposition"
  end

  test "openapi.json compose endpoint documents paper_size enum matching catalog" do
    get "/api/v1/openapi.json"
    assert_response :success
    paper_size_param = json.dig("paths", "/noshi", "get", "parameters")
                           .find { |p| p["name"] == "paper_size" }
    assert paper_size_param.present?, "paper_size parameter missing from /noshi"
    assert_equal NoshiCatalog::PAPER_SIZES, paper_size_param.dig("schema", "enum")
  end

  test "openapi.json ntype parameter maximum matches catalog" do
    get "/api/v1/openapi.json"
    assert_response :success
    ntype_param = json.dig("paths", "/noshi", "get", "parameters")
                      .find { |p| p["name"] == "ntype" }
    assert ntype_param.present?, "ntype parameter missing from /noshi"
    assert_equal NoshiCatalog::BUILTIN_DESIGN_COUNT, ntype_param.dig("schema", "maximum")
  end

  test "service manifest includes openapi endpoint reference" do
    get "/api/v1"
    assert_response :success
    assert json.dig("endpoints", "openapi").present?, "openapi key missing from service manifest"
    assert_includes json.dig("endpoints", "openapi"), "openapi.json"
  end

  test "backgrounds endpoint preloads uploaders instead of N+1 queries" do
    3.times do |i|
      owner = User.create!(provider: "google_oauth2", uid: "n1-#{i}", email: "n1-#{i}@x.com")
      bg = owner.backgrounds.build(title: "N1-#{i}", orientation: "landscape", status: "approved")
      bg.image.attach(io: File.open(Rails.root.join("test/fixtures/files/sample.png")),
                      filename: "sample.png", content_type: "image/png")
      bg.save!
    end

    user_loads = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      user_loads << payload[:sql] if !payload[:cached] && payload[:sql].match?(/FROM "users"/)
    end
    begin
      get "/api/v1/backgrounds"
    ensure
      ActiveSupport::Notifications.unsubscribe(sub)
    end

    assert_response :success
    assert_equal 3, json["count"]
    assert_equal 1, user_loads.size, "expected one preloaded users query, got #{user_loads.size}"
  end
end
