class Api::V1::Billing::CheckoutSessionsController < ApplicationController
  def create
    session = Billing::StripeCheckoutSessionCreator.call(
      user: current_user,
      success_url: AppConfig.validated_return_url(params[:success_url], fallback: AppConfig.checkout_success_url),
      cancel_url: AppConfig.validated_return_url(params[:cancel_url], fallback: AppConfig.checkout_cancel_url)
    )

    render json: {
      checkout_session: {
        id: session.id,
        url: session.url
      }
    }, status: :created
  end
end
