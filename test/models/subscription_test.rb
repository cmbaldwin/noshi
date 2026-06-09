require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  def stripe_sub(overrides = {})
    Stripe::Subscription.construct_from({
      id: "sub_123",
      customer: "cus_123",
      status: "active",
      current_period_end: 1.month.from_now.to_i,
      items: { data: [{ price: { id: "price_abc" } }] }
    }.merge(overrides))
  end

  test "active? is true for an active, unexpired subscription" do
    sub = Subscription.new(status: "active", current_period_end: 1.day.from_now)
    assert sub.active?
  end

  test "active? is false when canceled or expired" do
    assert_not Subscription.new(status: "canceled", current_period_end: 1.day.from_now).active?
    assert_not Subscription.new(status: "active", current_period_end: 1.day.ago).active?
  end

  test "upsert_from_stripe creates and links a subscription to the matching user" do
    user = User.create!(provider: "google_oauth2", uid: "u1", email: "a@b.com", stripe_customer_id: "cus_123")

    record = Subscription.upsert_from_stripe(stripe_sub)
    assert_equal user, record.user
    assert_equal "active", record.status
    assert_equal "price_abc", record.stripe_price_id
    assert user.reload.image_storage?
  end

  test "upsert_from_stripe updates the existing record (no duplicate)" do
    User.create!(provider: "google_oauth2", uid: "u2", email: "c@d.com", stripe_customer_id: "cus_123")
    Subscription.upsert_from_stripe(stripe_sub)

    assert_no_difference -> { Subscription.count } do
      Subscription.upsert_from_stripe(stripe_sub(status: "canceled"))
    end
    assert_equal "canceled", Subscription.find_by(stripe_subscription_id: "sub_123").status
  end

  test "upsert_from_stripe ignores unknown customers" do
    assert_nil Subscription.upsert_from_stripe(stripe_sub(customer: "cus_nope"))
  end
end
