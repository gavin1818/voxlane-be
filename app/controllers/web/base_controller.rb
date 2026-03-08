class Web::BaseController < ActionController::Base
  around_action :with_current_context
  before_action :load_web_session

  layout "marketing"
  protect_from_forgery with: :exception

  helper_method :current_user, :current_entitlement, :authenticated?, :current_user_email

  rescue_from Auth::SupabaseOtpClient::RequestError, with: :redirect_with_service_error
  rescue_from Stripe::StripeError, with: :redirect_with_service_error

  private

  def with_current_context
    Current.reset
    yield
  ensure
    Current.reset
  end

  def load_web_session
    @authenticated_session = session_authenticator.call
    return unless @authenticated_session

    Current.auth_claims = @authenticated_session.claims
    Current.user = @authenticated_session.user
  end

  def session_authenticator
    @session_authenticator ||= Web::SessionAuthenticator.new(session: session)
  end

  def current_user
    @authenticated_session&.user
  end

  def current_entitlement
    @authenticated_session&.entitlement
  end

  def current_user_email
    current_user&.email || session_authenticator.email
  end

  def authenticated?
    current_user.present?
  end

  def authenticate_web_user!
    return if authenticated?

    session[:after_sign_in_path] = request.fullpath if request.get?
    redirect_to login_path, alert: "Sign in to continue."
  end

  def redirect_after_sign_in(default:)
    requested_path = session.delete(:after_sign_in_path)

    if requested_path.present? && requested_path.start_with?("/") && !requested_path.start_with?("//")
      redirect_to requested_path
    else
      redirect_to default
    end
  end

  def redirect_with_service_error(error)
    redirect_back fallback_location: pricing_path, alert: error.message
  end
end
