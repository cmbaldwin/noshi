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

  test "checkout degrades gracefully when Stripe is unconfigured" do
    sign_in_as(create_user)
    post billing_checkout_path
    assert_redirected_to billing_path
    follow_redirect!
    assert_match I18n.t("billing.unavailable"), @response.body
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
