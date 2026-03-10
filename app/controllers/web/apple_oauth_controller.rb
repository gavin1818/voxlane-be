class Web::AppleOauthController < Web::BaseController
  skip_forgery_protection only: :callback

  def start
    return if redirect_authenticated_user_with_pending_desktop_login!

    session[:apple_oauth_state] = Auth::TokenGenerator.call
    session[:apple_oauth_nonce] = Auth::TokenGenerator.call

    redirect_to(
      Auth::AppleOauthClient.authorization_url(
        state: session[:apple_oauth_state],
        nonce: session[:apple_oauth_nonce]
      ),
      allow_other_host: true
    )
  end

  def callback
    if params[:error].present?
      redirect_to login_path, alert: params[:error_description].presence || "Apple sign-in was cancelled."
      return
    end

    returned_state = params[:state].to_s
    expected_state = session.delete(:apple_oauth_state).to_s
    expected_nonce = session.delete(:apple_oauth_nonce).to_s

    unless returned_state.present? && expected_state.present? &&
      ActiveSupport::SecurityUtils.secure_compare(returned_state, expected_state)
      redirect_to login_path, alert: "Apple sign-in could not be verified."
      return
    end

    if params[:code].blank?
      redirect_to login_path, alert: "Apple sign-in did not return an authorization code."
      return
    end

    token_payload = Auth::AppleOauthClient.exchange_code!(code: params[:code].to_s)
    claims = Auth::AppleIdentityTokenVerifier.call(
      id_token: token_payload.fetch("id_token"),
      nonce: expected_nonce
    )
    user = Auth::AppleUserResolver.call(
      claims: claims,
      user_payload: parsed_user_payload(params[:user])
    )

    complete_web_authentication!(
      user,
      notice: "Signed in with Apple.",
      auth_method: AuthIdentity::PROVIDER_APPLE
    )
  end

  private

  def parsed_user_payload(raw_value)
    case raw_value
    when ActionController::Parameters
      raw_value.to_unsafe_h
    when Hash
      raw_value
    when String
      raw_value.present? ? JSON.parse(raw_value) : {}
    else
      {}
    end
  rescue JSON::ParserError
    {}
  end
end
