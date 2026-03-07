module Billing
  class StripeCheckoutSessionCreator
    def self.call(user:, success_url:, cancel_url:)
      new(user:, success_url:, cancel_url:).call
    end

    def initialize(user:, success_url:, cancel_url:)
      @user = user
      @success_url = success_url
      @cancel_url = cancel_url
    end

    def call
      if user.email.blank?
        user.errors.add(:email, "must be present to create a Stripe Checkout session")
        raise ActiveRecord::RecordInvalid.new(user)
      end

      customer = StripeCustomerResolver.call(user)

      Stripe::Checkout::Session.create(
        mode: "subscription",
        customer: customer.external_customer_id,
        client_reference_id: user.supabase_uid,
        success_url: success_url,
        cancel_url: cancel_url,
        allow_promotion_codes: true,
        line_items: [
          {
            price: AppConfig.stripe_price_id,
            quantity: 1
          }
        ],
        subscription_data: {
          metadata: {
            user_id: user.id,
            supabase_uid: user.supabase_uid,
            entitlement_key: AppConfig.entitlement_key
          }
        }
      )
    end

    private

    attr_reader :user, :success_url, :cancel_url
  end
end
