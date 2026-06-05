class BillingController < ApplicationController
  before_action :require_login, except: :webhook
  # Stripe posts the webhook server-to-server with no CSRF token.
  skip_before_action :verify_authenticity_token, only: :webhook, raise: false

  def show
    @subscription = current_user.subscription
    @configured = Billing.configured?
  end

  # Start a Stripe Checkout subscription session.
  def checkout
    return redirect_to billing_path, alert: t("billing.unavailable") unless Billing.configured?

    session = Stripe::Checkout::Session.create(
      mode: "subscription",
      customer: ensure_stripe_customer,
      line_items: [{ price: ENV["STRIPE_PRICE_ID"], quantity: 1 }],
      success_url: billing_url(status: "success"),
      cancel_url: billing_url(status: "cancel"),
      client_reference_id: current_user.id
    )
    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe checkout failed: #{e.message}")
    redirect_to billing_path, alert: t("billing.unavailable")
  end

  # Stripe-hosted billing portal for managing/cancelling the subscription.
  def portal
    customer_id = current_user.stripe_customer_id
    return redirect_to billing_path, alert: t("billing.unavailable") if customer_id.blank?

    session = Stripe::BillingPortal::Session.create(customer: customer_id, return_url: billing_url)
    redirect_to session.url, allow_other_host: true, status: :see_other
  rescue Stripe::StripeError => e
    Rails.logger.error("Stripe portal failed: #{e.message}")
    redirect_to billing_path, alert: t("billing.unavailable")
  end

  def webhook
    event = verified_event(request.body.read, request.env["HTTP_STRIPE_SIGNATURE"])
    return head :bad_request unless event

    case event.type
    when "customer.subscription.created",
         "customer.subscription.updated",
         "customer.subscription.deleted"
      Subscription.upsert_from_stripe(event.data.object)
    end

    head :ok
  end

  private

  def ensure_stripe_customer
    return current_user.stripe_customer_id if current_user.stripe_customer_id.present?

    customer = Stripe::Customer.create(email: current_user.email, metadata: { user_id: current_user.id })
    current_user.update!(stripe_customer_id: customer.id)
    customer.id
  end

  def verified_event(payload, signature)
    secret = ENV["STRIPE_WEBHOOK_SECRET"]
    if secret.present?
      Stripe::Webhook.construct_event(payload, signature, secret)
    else
      # No secret configured (e.g. local/dev): accept unverified for convenience.
      Stripe::Event.construct_from(JSON.parse(payload, symbolize_names: true))
    end
  rescue JSON::ParserError, Stripe::SignatureVerificationError => e
    Rails.logger.warn("Stripe webhook rejected: #{e.message}")
    nil
  end
end
