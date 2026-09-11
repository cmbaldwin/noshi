# frozen_string_literal: true

require "test_helper"

class MarkdownForAgentsTest < ActionDispatch::IntegrationTest
  test "Accept text/markdown on the homepage does not 406" do
    get "/", headers: { "Accept" => "text/markdown, text/html, */*" }
    assert_response :success
    assert_includes response.media_type.to_s, "markdown"
    refute_match(/<html/i, response.body)
  end

  test "health check is not converted to markdown" do
    get "/up", headers: { "Accept" => "text/markdown" }
    assert_response :success
    refute_includes response.media_type.to_s, "markdown"
  end

  test "JSON API is not converted even with a markdown-preferring Accept" do
    get "/api/v1/", headers: { "Accept" => "text/markdown, text/html, */*" }
    assert_response :success
    assert_equal "application/json", response.media_type
  end

  test "query params survive the Accept rewrite" do
    get "/?locale=en", headers: { "Accept" => "text/markdown, text/html, */*" }
    assert_response :success
    assert_includes response.media_type.to_s, "markdown"
  end
end
