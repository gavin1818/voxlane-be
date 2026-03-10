require "test_helper"

class Billing::StripeCheckoutSessionCreatorTest < ActiveSupport::TestCase
  private def create_user(email:)
    User.create!(
      public_id: SecureRandom.uuid,
      email:,
      display_name: "Checkout Creator User",
      skip_password_requirement: true,
      email_verified_at: Time.current,
      profile: {}
    )
  end

  test "appends the checkout session placeholder to the success url" do
    user = create_user(email: "creator@example.com")
    stripe_customer = Struct.new(:external_customer_id).new("cus_creator")
    created_session = Struct.new(:id, :url).new("cs_creator", "https://checkout.stripe.com/c/pay/cs_creator")
    captured_payload = nil
    resolved_user_email = nil

    with_stubbed_singleton_method(
      Billing::StripeCustomerResolver,
      :call,
      ->(user) {
        resolved_user_email = user.email
        stripe_customer
      }
    ) do
      with_stubbed_singleton_method(
        Stripe::Checkout::Session,
        :create,
        ->(payload) {
          captured_payload = payload
          created_session
        }
      ) do
        session = Billing::StripeCheckoutSessionCreator.call(
          user:,
          success_url: "https://voxlane.io/account?checkout=success",
          cancel_url: "https://voxlane.io/pricing?checkout=cancelled"
        )

        assert_equal created_session, session
      end
    end

    assert_equal "creator@example.com", resolved_user_email
    assert_equal "https://voxlane.io/account?checkout=success&session_id={CHECKOUT_SESSION_ID}", captured_payload[:success_url]
    assert_equal "cus_creator", captured_payload[:customer]
    assert_equal user.public_id, captured_payload[:client_reference_id]
  end
end
