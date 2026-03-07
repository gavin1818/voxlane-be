class Api::V1::Billing::PortalSessionsController < ApplicationController
  def create
    session = Billing::StripePortalSessionCreator.call(
      user: current_user,
      return_url: AppConfig.validated_return_url(params[:return_url], fallback: AppConfig.portal_return_url)
    )

    render json: {
      portal_session: {
        url: session.url
      }
    }, status: :created
  end
end
