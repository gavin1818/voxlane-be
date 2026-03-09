class Web::BillingController < Web::BaseController
  before_action :authenticate_web_user!

  def checkout
    checkout_session = Billing::StripeCheckoutSessionCreator.call(
      user: current_user,
      success_url: AppConfig.validated_return_url(
        checkout_params[:success_url],
        fallback: AppConfig.checkout_success_url
      ),
      cancel_url: AppConfig.validated_return_url(
        checkout_params[:cancel_url],
        fallback: AppConfig.checkout_cancel_url
      )
    )

    redirect_to checkout_session.url, allow_other_host: true
  end

  def portal
    portal_session = Billing::StripePortalSessionCreator.call(
      user: current_user,
      return_url: AppConfig.validated_return_url(
        portal_params[:return_url],
        fallback: AppConfig.portal_return_url
      )
    )

    redirect_to portal_session.url, allow_other_host: true
  end

  def cancel_subscription
    subscription = Billing::StripeSubscriptionManager.cancel_at_period_end(user: current_user)
    period_end = subscription.current_period_end_at&.strftime("%b %-d, %Y")
    message = period_end.present? ? "Subscription will end on #{period_end}." : "Subscription cancellation scheduled."

    redirect_to account_path, notice: message
  end

  def resume_subscription
    Billing::StripeSubscriptionManager.resume(user: current_user)

    redirect_to account_path, notice: "Subscription will renew automatically."
  end

  private

  def checkout_params
    params.permit(:success_url, :cancel_url)
  end

  def portal_params
    params.permit(:return_url)
  end
end
