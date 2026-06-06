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

  test "backgrounds endpoint lists only approved uploads" do
    user = User.create!(provider: "google_oauth2", uid: "api2", email: "api2@x.com")
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
end
