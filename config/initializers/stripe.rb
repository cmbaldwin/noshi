# Stripe billing for the paid image-storage tier. Keys come from env
# (.kamal/secrets in production, .env in development). The app boots fine
# without them; billing actions degrade gracefully when unconfigured.
Stripe.api_key = ENV["STRIPE_SECRET_KEY"] if ENV["STRIPE_SECRET_KEY"].present?

module Billing
  def self.configured?
    ENV["STRIPE_SECRET_KEY"].present? && ENV["STRIPE_PRICE_ID"].present?
  end
end
