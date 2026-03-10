require "test_helper"

class Billing::StripeCheckoutCompletionSyncTest < ActiveSupport::TestCase
  private def create_user(email:)
    User.create!(
      public_id: SecureRandom.uuid,
      email:,
      display_name: "Checkout Sync User",
      skip_password_requirement: true,
      email_verified_at: Time.current,
      profile: {}
    )
  end

  test "syncs a checkout session that belongs to the user" do
    user = create_user(email: "sync@example.com")
    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_checkout_sync",
      livemode: false,
      metadata: {}
    )
    stripe_subscription = Struct.new(:id, :metadata).new(
      "sub_checkout_sync",
      { "user_id" => user.id.to_s, "public_id" => user.public_id }
    )
    checkout_session = Struct.new(:mode, :subscription, :client_reference_id, :customer).new(
      "subscription",
      stripe_subscription,
      user.public_id,
      customer.external_customer_id
    )
    synced_subscription = Struct.new(:user_id).new(user.id)
    retrieved_payload = nil
    synced_argument = nil

    with_stubbed_singleton_method(
      Stripe::Checkout::Session,
      :retrieve,
      lambda { |payload|
        retrieved_payload = payload
        checkout_session
      }
    ) do
      with_stubbed_singleton_method(
        Billing::StripeSubscriptionSync,
        :call,
        ->(subscription) {
          synced_argument = subscription
          synced_subscription
        }
      ) do
        assert_equal synced_subscription, Billing::StripeCheckoutCompletionSync.call(
          user:,
          checkout_session_id: "cs_checkout_sync"
        )
      end
    end

    assert_equal "cs_checkout_sync", retrieved_payload[:id]
    assert_equal ["subscription"], retrieved_payload[:expand]
    assert_equal stripe_subscription, synced_argument
  end

  test "skips checkout sessions that do not belong to the user" do
    user = create_user(email: "skip@example.com")
    user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_checkout_skip",
      livemode: false,
      metadata: {}
    )
    stripe_subscription = Struct.new(:id, :metadata).new("sub_checkout_skip", {})
    checkout_session = Struct.new(:mode, :subscription, :client_reference_id, :customer).new(
      "subscription",
      stripe_subscription,
      "another-user",
      "cus_someone_else"
    )

    with_stubbed_singleton_method(
      Stripe::Checkout::Session,
      :retrieve,
      ->(_payload) { checkout_session }
    ) do
      with_stubbed_singleton_method(
        Billing::StripeSubscriptionSync,
        :call,
        ->(_subscription) { flunk "Expected checkout sync to reject a mismatched session" }
      ) do
        assert_nil Billing::StripeCheckoutCompletionSync.call(user:, checkout_session_id: "cs_checkout_skip")
      end
    end
  end
end
