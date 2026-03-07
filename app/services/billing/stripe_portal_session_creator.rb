module Billing
  class StripePortalSessionCreator
    def self.call(user:, return_url:)
      new(user:, return_url:).call
    end

    def initialize(user:, return_url:)
      @user = user
      @return_url = return_url
    end

    def call
      customer = user.billing_customers.find_by(provider: BillingCustomer::PROVIDER_STRIPE)
      raise ActiveRecord::RecordNotFound, "No Stripe customer found for this user" if customer.blank?

      Stripe::BillingPortal::Session.create(
        customer: customer.external_customer_id,
        return_url: return_url
      )
    end

    private

    attr_reader :user, :return_url
  end
end
