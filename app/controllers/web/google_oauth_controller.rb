class Web::GoogleOauthController < Web::BaseController
  def start
    session[:google_oauth_state] = Auth::TokenGenerator.call
    redirect_to Auth::GoogleOauthClient.authorization_url(state: session[:google_oauth_state]), allow_other_host: true
  end

  def callback
    returned_state = params[:state].to_s
    expected_state = session.delete(:google_oauth_state).to_s

    unless returned_state.present? && expected_state.present? &&
      ActiveSupport::SecurityUtils.secure_compare(returned_state, expected_state)
      redirect_to login_path, alert: "Google sign-in could not be verified."
      return
    end

    profile = Auth::GoogleOauthClient.fetch_profile!(code: params[:code].to_s)
    user = Auth::GoogleUserResolver.call(profile)

    complete_web_authentication!(user, notice: "Signed in with Google.")
  end
end
