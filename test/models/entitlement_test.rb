require "test_helper"

class EntitlementTest < ActiveSupport::TestCase
  test "reconciler grants active access when the user has an active stripe subscription" do
    user = User.create!(
      public_id: "subscriber-1",
      email: "subscriber@voxlane.io",
      display_name: "Subscriber",
      skip_password_requirement: true,
      email_verified_at: Time.current,
      profile: {}
    )

    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_123",
      livemode: false,
      metadata: {}
    )

    user.subscriptions.create!(
      billing_customer: customer,
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_subscription_id: "sub_123",
      external_price_id: "price_test_123",
      status: "active",
      current_period_end_at: 30.days.from_now,
      metadata: {}
    )

    entitlement = Entitlements::Reconciler.call(user)

    assert_equal "active", entitlement.status
    assert_equal true, entitlement.access_granted?
    assert_equal BillingCustomer::PROVIDER_STRIPE, entitlement.source
  end
end
