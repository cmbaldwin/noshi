require "test_helper"

class BillingTest < ActiveSupport::TestCase
  # Set/clear ENV around a block, restoring originals afterward.
  def with_env(vars)
    keys = vars.keys
    original = ENV.to_h.slice(*keys)
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    keys.each { |k| ENV.delete(k) }
    original.each { |k, v| ENV[k] = v }
  end

  test "price_id_problems flags a product id pasted where a price id belongs" do
    with_env("STRIPE_MONTHLY_PRICE_ID" => "prod_ABC123", "STRIPE_YEARLY_PRICE_ID" => "price_OK") do
      problems = Billing.price_id_problems
      assert_equal 1, problems.size
      assert_match(/STRIPE_MONTHLY_PRICE_ID/, problems.first)
      assert_match(/product id/, problems.first)
    end
  end

  test "price_id_problems is empty for valid price ids and ignores blanks" do
    with_env("STRIPE_MONTHLY_PRICE_ID" => "price_M", "STRIPE_YEARLY_PRICE_ID" => "") do
      assert_empty Billing.price_id_problems
    end
  end

  test "price_id_problems flags any non-price_ value, not just prod_" do
    with_env("STRIPE_MONTHLY_PRICE_ID" => "sk_live_oops", "STRIPE_YEARLY_PRICE_ID" => nil) do
      problems = Billing.price_id_problems
      assert_equal 1, problems.size
      assert_match(/unexpected format/, problems.first)
    end
  end

  test "available_plans only includes plans with a configured price" do
    with_env("STRIPE_MONTHLY_PRICE_ID" => "price_M", "STRIPE_YEARLY_PRICE_ID" => "") do
      assert_equal ["monthly"], Billing.available_plans
    end
  end
end
