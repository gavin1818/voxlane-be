module Billing
  class StripeUserResolver
    def self.call(subscription:)
      new(subscription:).call
    end

    def initialize(subscription:)
      @subscription = subscription
    end

    def call
      customer_id = subscription.customer
      billing_customer = BillingCustomer.find_by(
        provider: BillingCustomer::PROVIDER_STRIPE,
        external_customer_id: customer_id
      )
      return [billing_customer.user, billing_customer] if billing_customer.present?

      customer = Stripe::Customer.retrieve(customer_id)
      metadata = customer.metadata.to_h.presence || subscription.metadata.to_h

      user = resolve_user(metadata)
      raise ActiveRecord::RecordNotFound, "Unable to resolve user for Stripe customer #{customer_id}" if user.blank?

      billing_customer = user.billing_customers.find_or_create_by!(
        provider: BillingCustomer::PROVIDER_STRIPE
      ) do |record|
        record.external_customer_id = customer.id
        record.livemode = customer.livemode
        record.metadata = customer.to_hash
      end

      billing_customer.update!(
        external_customer_id: customer.id,
        livemode: customer.livemode,
        metadata: customer.to_hash
      )

      [user, billing_customer]
    end

    private

    attr_reader :subscription

    def resolve_user(metadata)
      return User.find_by(id: metadata["user_id"]) if metadata["user_id"].present?
      return User.find_by(supabase_uid: metadata["supabase_uid"]) if metadata["supabase_uid"].present?

      nil
    end
  end
end
