# Stripe billing for the paid image-storage tier. Keys come from env
# (.kamal/secrets in production, .env in development). The app boots fine
# without them; billing actions degrade gracefully when unconfigured.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"] if ENV["STRIPE_SECRET_KEY"].present?

module Billing
  PRICE_IDS = {
    "monthly" => "STRIPE_MONTHLY_PRICE_ID",
    "yearly"  => "STRIPE_YEARLY_PRICE_ID"
  }.freeze

  def self.configured?
    ENV["STRIPE_SECRET_KEY"].present? && PRICE_IDS.values.any? { |k| ENV[k].present? }
  end

  # Stripe price id for a plan ("monthly"/"yearly"), or nil if not configured.
  def self.price_id(plan)
    key = PRICE_IDS[plan.to_s]
    ENV[key].presence if key
  end

  # Plans that actually have a price configured, in display order.
  def self.available_plans
    PRICE_IDS.keys.select { |plan| price_id(plan) }
  end
end
