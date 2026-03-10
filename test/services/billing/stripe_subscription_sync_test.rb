require "test_helper"

class Billing::StripeSubscriptionSyncTest < ActiveSupport::TestCase
  private def create_user(email:)
    User.create!(
      public_id: SecureRandom.uuid,
      email:,
      display_name: "Stripe Sync User",
      skip_password_requirement: true,
      email_verified_at: Time.current,
      profile: {}
    )
  end

  test "falls back to the primary subscription item period end when stripe omits a top-level current period end" do
    user = create_user(email: "stripe-sync@example.com")
    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_stripe_sync",
      livemode: false,
      metadata: {}
    )
    period_end = 1.month.from_now.change(usec: 0)
    stripe_subscription = Struct.new(
      :id,
      :items,
      :status,
      :cancel_at_period_end,
      :canceled_at,
      :metadata,
      :to_hash
    ).new(
      "sub_stripe_sync",
      Struct.new(:data).new([
        Struct.new(:price, :to_hash).new(
          Struct.new(:id).new("price_test_123"),
          { current_period_end: period_end.to_i }
        )
      ]),
      "active",
      false,
      nil,
      {},
      { current_period_end: nil, trial_end: nil }
    )
    resolved_subscription = nil

    with_stubbed_singleton_method(
      Billing::StripeUserResolver,
      :call,
      ->(subscription:) {
        resolved_subscription = subscription
        [user, customer]
      }
    ) do
      subscription = Billing::StripeSubscriptionSync.call(stripe_subscription)

      assert_equal "sub_stripe_sync", subscription.external_subscription_id
      assert_equal "price_test_123", subscription.external_price_id
      assert_equal period_end, subscription.current_period_end_at
    end

    assert_equal stripe_subscription, resolved_subscription
  end
end
