module Billing
  class StripeWebhookProcessor
    SUPPORTED_EVENTS = [
      "checkout.session.completed",
      "customer.subscription.created",
      "customer.subscription.updated",
      "customer.subscription.deleted",
      "invoice.paid"
    ].freeze

    def self.call(event)
      new(event).call
    end

    def initialize(event)
      @event = event
    end

    def call
      record = WebhookEvent.find_or_initialize_by(
        provider: BillingCustomer::PROVIDER_STRIPE,
        external_event_id: event.id
      )
      return if record.processed_at.present?

      record.event_type = event.type
      record.payload = event.to_hash
      record.save!

      process!

      record.update!(processed_at: Time.current)
    end

    private

    attr_reader :event

    def process!
      return unless SUPPORTED_EVENTS.include?(event.type)

      case event.type
      when "checkout.session.completed"
        session = event.data.object
        return unless session.mode == "subscription" && session.subscription.present?

        StripeSubscriptionSync.call(session.subscription)
      when "customer.subscription.created", "customer.subscription.updated", "customer.subscription.deleted"
        StripeSubscriptionSync.call(event.data.object)
      when "invoice.paid"
        invoice = event.data.object
        StripeSubscriptionSync.call(invoice.subscription) if invoice.subscription.present?
      end
    end
  end
end
