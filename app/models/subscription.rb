class Subscription < ApplicationRecord
  belongs_to :user

  # Stripe statuses that grant the paid image-storage entitlement.
  ACTIVE_STATUSES = %w[active trialing].freeze

  def active?
    ACTIVE_STATUSES.include?(status) &&
      (current_period_end.nil? || current_period_end.future?)
  end
end
