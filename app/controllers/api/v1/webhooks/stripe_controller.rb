class Api::V1::Webhooks::StripeController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    event = Stripe::Webhook.construct_event(
      request.raw_post,
      request.headers["Stripe-Signature"],
      ENV.fetch("STRIPE_WEBHOOK_SECRET")
    )

    Billing::StripeWebhookProcessor.call(event)

    render json: { received: true }
  rescue JSON::ParserError, Stripe::SignatureVerificationError => error
    render json: { error: error.message }, status: :bad_request
  end
end
