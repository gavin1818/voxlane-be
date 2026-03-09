class Api::V1::Auth::SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    user = User.find_by(email: normalized_email(session_params[:email]))
    authenticated_user = user&.authenticate(session_params[:password].to_s)

    unless authenticated_user
      raise Auth::UnauthorizedError, "Invalid email or password."
    end

    render json: Auth::SessionIssuer.call(
      user: authenticated_user,
      auth_method: "password",
      metadata: request_metadata
    )
  end

  def refresh
    render json: Auth::SessionRefresher.call(refresh_token: refresh_params[:refresh_token])
  end

  private

  def session_params
    params.require(:auth).permit(:email, :password)
  end

  def refresh_params
    params.require(:auth).permit(:refresh_token)
  end

  def normalized_email(value)
    value.to_s.strip.downcase
  end

  def request_metadata
    {
      "ip_address" => request.remote_ip,
      "user_agent" => request.user_agent
    }
  end
end
