require "test_helper"

class NoshisControllerTest < ActionDispatch::IntegrationTest
  test "GET / renders the noshi form" do
    get "/"
    assert_response :success
    assert_select "form#new_noshi"
  end

  test "GET /ja renders the noshi form in Japanese" do
    get "/ja"
    assert_response :success
    assert_select "form#new_noshi"
  end

  test "GET /en renders the noshi form in English" do
    get "/en"
    assert_response :success
    assert_select "form#new_noshi"
  end

  test "GET /about renders the about page" do
    get "/about"
    assert_response :success
  end

  test "GET /privacy renders the privacy policy page" do
    get "/privacy"
    assert_response :success
  end

  test "GET /en/privacy renders privacy page in English" do
    get "/en/privacy"
    assert_response :success
    assert_select "h1", text: "Privacy Policy"
  end

  test "GET /terms renders the terms of use page" do
    get "/terms"
    assert_response :success
  end

  test "GET /en/terms renders terms page in English" do
    get "/en/terms"
    assert_response :success
    assert_select "h1", text: "Terms of Use"
  end

  test "GET /noshis/new renders the form" do
    get "/noshis/new"
    assert_response :success
    assert_select "form#new_noshi"
  end

  test "GET /noshis/new with URL params renders the form" do
    get URI::DEFAULT_PARSER.escape("/noshis/new/1/foo,bar/御祝")
    assert_response :success
    assert_select "form#new_noshi"
  end

  test "GET /up returns ok health status" do
    get "/up"
    assert_response :success
  end
end
