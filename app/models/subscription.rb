class Subscription < ApplicationRecord
  belongs_to :user

  # Stripe statuses that grant the paid image-storage entitlement.
  ACTIVE_STATUSES = %w[active trialing].freeze

  def active?
    ACTIVE_STATUSES.include?(status) &&
      (current_period_end.nil? || current_period_end.future?)
  end

  # Create or update the local subscription record from a Stripe subscription
  # object (from a webhook event or an API retrieve). Returns nil if we can't
  # match the Stripe customer to a local user. Kept free of network calls so it
  # is straightforward to test.
  def self.upsert_from_stripe(stripe_sub)
    user = User.find_by(stripe_customer_id: stripe_sub["customer"])
    return nil unless user

    record = find_or_initialize_by(stripe_subscription_id: stripe_sub["id"])
    record.user = user
    record.status = stripe_sub["status"]
    record.stripe_price_id = extract_price_id(stripe_sub)
    period_end = stripe_sub["current_period_end"]
    record.current_period_end = period_end ? Time.at(period_end.to_i) : nil
    record.save!
    record
  end

  def self.extract_price_id(stripe_sub)
    stripe_sub["items"]["data"].first["price"]["id"]
  rescue StandardError
    nil
  end
end
