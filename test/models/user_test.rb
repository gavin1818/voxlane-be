require "test_helper"

class UserTest < ActiveSupport::TestCase
  private def create_user(email:)
    User.create!(
      public_id: SecureRandom.uuid,
      email:,
      display_name: "Test User",
      skip_password_requirement: true,
      email_verified_at: Time.current,
      profile: {}
    )
  end

  test "active subscription prefers the access-granting subscription with the latest period end" do
    user = create_user(email: "subscriber@example.com")
    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_active_user_test",
      livemode: false,
      metadata: {}
    )

    older_trial = user.subscriptions.create!(
      billing_customer: customer,
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_subscription_id: "sub_trial_old",
      external_price_id: "price_test_123",
      status: "trialing",
      current_period_end_at: 7.days.from_now,
      metadata: {}
    )
    newer_active = user.subscriptions.create!(
      billing_customer: customer,
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_subscription_id: "sub_active_new",
      external_price_id: "price_test_456",
      status: "active",
      current_period_end_at: 30.days.from_now,
      metadata: {}
    )

    assert_equal newer_active, user.active_subscription
    assert_not_equal older_trial, user.active_subscription
  end

  test "display subscription falls back to the newest subscription when none grant access" do
    user = create_user(email: "inactive@example.com")
    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_inactive_user_test",
      livemode: false,
      metadata: {}
    )

    older_incomplete = user.subscriptions.create!(
      billing_customer: customer,
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_subscription_id: "sub_incomplete_old",
      external_price_id: "price_test_123",
      status: "incomplete",
      current_period_end_at: 1.day.from_now,
      metadata: {}
    )
    newer_expired = user.subscriptions.create!(
      billing_customer: customer,
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_subscription_id: "sub_incomplete_expired_new",
      external_price_id: "price_test_456",
      status: "incomplete_expired",
      current_period_end_at: nil,
      metadata: {}
    )

    older_incomplete.update_column(:updated_at, 2.days.ago)
    newer_expired.update_column(:updated_at, 1.day.ago)

    assert_nil user.active_subscription
    assert_equal newer_expired, user.display_subscription
  end
end
