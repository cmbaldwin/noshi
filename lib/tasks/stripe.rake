namespace :stripe do
  desc "Verify the configured Stripe price ids are real, active, recurring prices. " \
       "Runs in the Kamal pre-build gate so a bad price id can't reach production."
  task verify: :environment do
    unless Billing.configured?
      puts "stripe:verify: Stripe not configured (no key/price env) — skipping."
      next
    end

    # 1. Cheap, offline format check (catches prod_… pasted as a price id).
    problems = Billing.price_id_problems
    abort "✗ stripe:verify failed:\n  - #{problems.join("\n  - ")}" if problems.any?

    # 2. Confirm each price actually exists and is an active recurring price.
    failures = Billing.available_plans.filter_map do |plan|
      id = Billing.price_id(plan)
      begin
        price = Stripe::Price.retrieve(id)
        unless price.active && price.recurring
          "#{plan} (#{id}): not an active recurring price"
        end
      rescue Stripe::StripeError => e
        "#{plan} (#{id}): #{e.message}"
      end
    end
    abort "✗ stripe:verify failed:\n  - #{failures.join("\n  - ")}" if failures.any?

    plans = Billing.available_plans.join(", ")
    puts "✓ stripe:verify: #{plans} price(s) are valid active recurring prices."
  end
end
