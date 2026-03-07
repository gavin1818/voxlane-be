class ApplicationController < ActionController::API
  around_action :with_current_context
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from Auth::SupabaseOtpClient::RequestError, with: :render_auth_request_error
  rescue_from Auth::UnauthorizedError, with: :render_unauthorized
  rescue_from Stripe::StripeError, with: :render_stripe_error
  rescue_from KeyError, with: :render_configuration_error

  private

  def authenticate_user!
    claims = Auth::SupabaseTokenVerifier.call(bearer_token)
    Current.auth_claims = claims
    Current.user = Auth::UserSync.call(claims)
  end

  def current_user
    Current.user
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    scheme, token = header.split(" ", 2)

    return token if scheme.to_s.casecmp("bearer").zero? && token.present?

    raise Auth::UnauthorizedError, "Missing bearer token"
  end

  def with_current_context
    Current.reset
    yield
  ensure
    Current.reset
  end

  def render_record_invalid(error)
    render json: { error: error.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def render_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def render_unauthorized(error)
    render json: { error: error.message }, status: :unauthorized
  end

  def render_auth_request_error(error)
    status = error.status.present? ? error.status : :bad_gateway
    render json: { error: error.message }, status: status
  end

  def render_stripe_error(error)
    render json: { error: error.message }, status: :bad_gateway
  end

  def render_configuration_error(error)
    render json: { error: error.message }, status: :internal_server_error
  end
end
