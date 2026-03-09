module Billing
  class StripeSubscriptionManager
    def self.cancel_at_period_end(user:)
      new(user:, cancel_at_period_end: true).call
    end

    def self.resume(user:)
      new(user:, cancel_at_period_end: false).call
    end

    def initialize(user:, cancel_at_period_end:)
      @user = user
      @cancel_at_period_end = cancel_at_period_end
    end

    def call
      local_subscription = target_subscription
      raise ActiveRecord::RecordNotFound, "No Stripe subscription found for this user" if local_subscription.blank?

      stripe_subscription = Stripe::Subscription.update(
        local_subscription.external_subscription_id,
        { cancel_at_period_end: cancel_at_period_end }
      )

      StripeSubscriptionSync.call(stripe_subscription)
    end

    private

    attr_reader :user, :cancel_at_period_end

    def target_subscription
      user.subscriptions
        .where(provider: BillingCustomer::PROVIDER_STRIPE)
        .order(updated_at: :desc, created_at: :desc)
        .find do |subscription|
          cancel_at_period_end ? subscription.cancellable? : subscription.resumable?
        end
    end
  end
end
