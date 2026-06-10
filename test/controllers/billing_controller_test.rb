require "test_helper"

class BillingControllerTest < ActionDispatch::IntegrationTest
  test "billing page requires login" do
    get billing_path
    assert_redirected_to root_path
  end

  test "signed-in user sees the plans page" do
    sign_in_as(create_user)
    get billing_path
    assert_response :success
    assert_match I18n.t("billing.plan_paid"), @response.body
  end

  test "configured billing page shows a checkout button per available plan" do
    keys = %w[STRIPE_SECRET_KEY STRIPE_MONTHLY_PRICE_ID STRIPE_YEARLY_PRICE_ID]
    original = ENV.to_h.slice(*keys)
    ENV["STRIPE_SECRET_KEY"]        = "sk_test_x"
    ENV["STRIPE_MONTHLY_PRICE_ID"]  = "price_monthly"
    ENV["STRIPE_YEARLY_PRICE_ID"]   = "price_yearly"

    sign_in_as(create_user)
    get billing_path
    assert_response :success
    assert_match I18n.t("billing.upgrade_monthly"), @response.body
    assert_match I18n.t("billing.upgrade_yearly"), @response.body
    assert_select "input[name=plan][value=monthly]"
    assert_select "input[name=plan][value=yearly]"
  ensure
    keys.each { |k| ENV.delete(k) }
    original.each { |k, v| ENV[k] = v }
  end

  test "checkout degrades gracefully when Stripe is unconfigured" do
    # Make the test deterministic regardless of any Stripe env the developer has
    # set (e.g. .env.development) — checkout must not reach the Stripe API here.
    keys = %w[STRIPE_SECRET_KEY STRIPE_MONTHLY_PRICE_ID STRIPE_YEARLY_PRICE_ID]
    original = ENV.to_h.slice(*keys)
    keys.each { |k| ENV.delete(k) }

    sign_in_as(create_user)
    post billing_checkout_path, params: { plan: "monthly" }
    assert_redirected_to billing_path
    follow_redirect!
    assert_match I18n.t("billing.unavailable"), @response.body
  ensure
    original.each { |k, v| ENV[k] = v }
  end

  test "webhook upserts a subscription from an event payload" do
    user = create_user(stripe_customer_id: "cus_777")
    payload = {
      type: "customer.subscription.created",
      data: {
        object: {
          id: "sub_777", customer: "cus_777", status: "active",
          current_period_end: 1.month.from_now.to_i,
          items: { data: [{ price: { id: "price_x" } }] }
        }
      }
    }.to_json

    assert_difference -> { Subscription.count }, 1 do
      post "/stripe/webhook", params: payload, headers: { "CONTENT_TYPE" => "application/json" }
    end
    assert_response :ok
    assert user.reload.image_storage?
  end

  test "webhook rejects unparseable payloads" do
    # text/plain so Rails doesn't pre-parse params; the body reaches our guard.
    post "/stripe/webhook", params: "not json", headers: { "CONTENT_TYPE" => "text/plain" }
    assert_response :bad_request
  end
end
