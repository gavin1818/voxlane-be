module Billing
  class StripeCheckoutCompletionSync
    def self.call(user:, checkout_session_id:)
      new(user:, checkout_session_id:).call
    end

    def initialize(user:, checkout_session_id:)
      @user = user
      @checkout_session_id = checkout_session_id
    end

    def call
      return if checkout_session_id.blank?
      return unless checkout_session.mode == "subscription"
      return if checkout_session.subscription.blank?
      return unless checkout_session_belongs_to_user?

      subscription = StripeSubscriptionSync.call(checkout_session.subscription)
      return unless subscription.user_id == user.id

      subscription
    end

    private

    attr_reader :user, :checkout_session_id

    def checkout_session
      @checkout_session ||= Stripe::Checkout::Session.retrieve(
        {
          id: checkout_session_id,
          expand: ["subscription"]
        }
      )
    end

    def checkout_session_belongs_to_user?
      return true if checkout_session.client_reference_id == user.public_id
      return true if checkout_session.customer.present? && checkout_session.customer == user.billing_customer&.external_customer_id

      subscription_metadata = checkout_session.subscription.respond_to?(:metadata) ? checkout_session.subscription.metadata.to_h : {}
      return true if subscription_metadata["user_id"].to_s == user.id.to_s
      return true if subscription_metadata["public_id"] == user.public_id

      false
    end
  end
end
