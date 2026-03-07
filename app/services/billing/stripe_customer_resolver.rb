module Billing
  class StripeCustomerResolver
    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return existing_customer if existing_customer.present?

      stripe_customer = Stripe::Customer.create(
        email: user.email,
        name: user.display_name,
        metadata: {
          user_id: user.id,
          supabase_uid: user.supabase_uid
        }
      )

      user.billing_customers.create!(
        provider: BillingCustomer::PROVIDER_STRIPE,
        external_customer_id: stripe_customer.id,
        livemode: stripe_customer.livemode,
        metadata: stripe_customer.to_hash
      )
    end

    private

    attr_reader :user

    def existing_customer
      user.billing_customers.find_by(provider: BillingCustomer::PROVIDER_STRIPE)
    end
  end
end
