class Web::BaseController < ActionController::Base
  around_action :with_current_context
  before_action :load_web_session

  layout "marketing"
  protect_from_forgery with: :exception

  helper_method :current_user, :current_entitlement, :authenticated?, :current_user_email, :google_oauth_enabled?, :apple_oauth_enabled?, :password_settings_visible?

  rescue_from Auth::GoogleOauthClient::RequestError, with: :redirect_with_service_error
  rescue_from Auth::AppleOauthClient::RequestError, with: :redirect_with_service_error
  rescue_from Auth::AppleIdentityTokenVerifier::RequestError, with: :redirect_with_service_error
  rescue_from Stripe::StripeError, with: :redirect_with_service_error

  private

  def with_current_context
    Current.reset
    yield
  ensure
    Current.reset
  end

  def load_web_session
    remember_pending_desktop_login_from_params!
    reload_web_session!
  end

  def reload_web_session!
    @authenticated_session = session_authenticator.call
    return unless @authenticated_session

    Current.auth_claims = @authenticated_session.claims
    Current.user = @authenticated_session.user
    Current.auth_session = @authenticated_session.auth_session
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
    current_user&.email
  end

  def current_web_auth_method
    @authenticated_session&.auth_method.to_s.presence
  end

  def password_settings_visible?
    return false unless current_user
    return true if current_user.password_login_enabled?

    !current_web_auth_method.in?([ AuthIdentity::PROVIDER_GOOGLE, AuthIdentity::PROVIDER_APPLE ])
  end

  def authenticated?
    current_user.present?
  end

  def google_oauth_enabled?
    AppConfig.google_oauth_enabled?
  end

  def apple_oauth_enabled?
    AppConfig.apple_oauth_enabled?
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

  def sign_in_web_user!(user, auth_method: nil)
    session_authenticator.store!(user, auth_method:)
    Current.user = user
  end

  def complete_web_authentication!(user, notice: nil, default_redirect: account_path, auth_method: nil)
    sign_in_web_user!(user, auth_method:)
    flash[:notice] = notice if notice.present?

    if (desktop_login_request = approve_pending_desktop_login_request(user))
      redirect_to desktop_login_path(desktop_login_request.public_id)
      return
    end

    redirect_after_sign_in(default: default_redirect)
  end

  def remember_desktop_login_request!(public_id)
    session[:pending_desktop_login_request_id] = public_id
  end

  def clear_pending_desktop_login_request!
    session.delete(:pending_desktop_login_request_id)
  end

  def redirect_authenticated_user_with_pending_desktop_login!(fallback: account_path)
    return false unless authenticated?

    if (desktop_login_request = pending_desktop_login_request)
      redirect_to desktop_login_path(desktop_login_request.public_id)
    else
      redirect_to fallback
    end

    true
  end

  def approve_pending_desktop_login_request(user)
    desktop_login_request = pending_desktop_login_request
    return if desktop_login_request.blank?

    clear_pending_desktop_login_request!
    return if desktop_login_request.user.present? && desktop_login_request.user != user

    desktop_login_request.approve!(user)
  end

  def remember_pending_desktop_login_from_params!
    public_id = params[:desktop_login].to_s.strip
    return if public_id.blank?

    desktop_login_request = DesktopLoginRequest.find_by(public_id: public_id)
    return if desktop_login_request.blank? || desktop_login_request.expired?

    remember_desktop_login_request!(public_id)
  end

  def pending_desktop_login_request
    public_id = session[:pending_desktop_login_request_id].to_s
    return if public_id.blank?

    desktop_login_request = DesktopLoginRequest.find_by(public_id: public_id)
    if desktop_login_request.blank? || desktop_login_request.expired?
      clear_pending_desktop_login_request!
      return
    end

    desktop_login_request
  end

  def redirect_with_service_error(error)
    redirect_back fallback_location: pricing_path, alert: error.message
  end
end
