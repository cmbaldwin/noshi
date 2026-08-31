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
end
