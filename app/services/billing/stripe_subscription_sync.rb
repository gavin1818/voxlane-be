module Billing
  class StripeSubscriptionSync
    def self.call(stripe_subscription_or_id)
      new(stripe_subscription_or_id).call
    end

    def initialize(stripe_subscription_or_id)
      @stripe_subscription_or_id = stripe_subscription_or_id
    end

    def call
      user, billing_customer = StripeUserResolver.call(subscription:)

      local_subscription = Subscription.find_or_initialize_by(
        provider: BillingCustomer::PROVIDER_STRIPE,
        external_subscription_id: subscription.id
      )

      local_subscription.assign_attributes(
        user: user,
        billing_customer: billing_customer,
        external_price_id: primary_item&.price&.id,
        status: subscription.status,
        current_period_end_at: timestamp(current_period_end_value),
        cancel_at_period_end: subscription.cancel_at_period_end,
        canceled_at: timestamp(subscription.canceled_at),
        metadata: subscription.to_hash
      )
      local_subscription.save!

      Entitlements::Reconciler.call(user)
      local_subscription
    end

    private

    attr_reader :stripe_subscription_or_id

    def subscription
      @subscription ||= if stripe_subscription_or_id.respond_to?(:id)
        stripe_subscription_or_id
      else
        Stripe::Subscription.retrieve(stripe_subscription_or_id)
      end
    end

    def primary_item
      @primary_item ||= subscription.items&.data&.first
    end

    def current_period_end_value
      subscription_hash = subscription.to_hash
      subscription_hash[:current_period_end] ||
        primary_item&.to_hash&.dig(:current_period_end) ||
        subscription_hash[:trial_end]
    end

    def timestamp(value)
      return if value.blank?

      Time.zone.at(value)
    end
  end
end
