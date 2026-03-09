require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  private def build_subscription(status:, cancel_at_period_end:)
    user = User.create!(
      public_id: SecureRandom.uuid,
      email: "#{SecureRandom.hex(4)}@example.com",
      display_name: "Test User",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current,
      profile: {}
    )
    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_#{SecureRandom.hex(4)}",
      livemode: false,
      metadata: {}
    )

    Subscription.new(
      user:,
      billing_customer: customer,
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_subscription_id: "sub_#{SecureRandom.hex(4)}",
      external_price_id: "price_test_123",
      status:,
      current_period_end_at: 1.month.from_now,
      cancel_at_period_end:,
      metadata: {}
    )
  end

  test "trialing subscriptions can be cancelled from the account page" do
    subscription = build_subscription(status: "trialing", cancel_at_period_end: false)

    assert subscription.cancellable?
    assert_not subscription.resumable?
  end

  test "scheduled cancellations can be resumed" do
    subscription = build_subscription(status: "active", cancel_at_period_end: true)

    assert_not subscription.cancellable?
    assert subscription.resumable?
  end

  test "subscriptions without stripe access cannot be managed" do
    subscription = build_subscription(status: "canceled", cancel_at_period_end: false)

    assert_not subscription.cancellable?
    assert_not subscription.resumable?
  end
end
