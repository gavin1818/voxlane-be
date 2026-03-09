class Api::V1::Auth::DesktopSessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    desktop_login_request, raw_polling_token = DesktopLoginRequest.issue!(
      metadata: {
        "ip_address" => request.remote_ip,
        "user_agent" => request.user_agent
      }
    )

    render json: {
      desktop_session: {
        request_id: desktop_login_request.public_id,
        polling_token: raw_polling_token,
        verification_url: "#{AppConfig.frontend_url.chomp("/")}#{desktop_login_path(desktop_login_request.public_id)}",
        expires_at: desktop_login_request.expires_at.iso8601,
        poll_interval_seconds: 2
      }
    }
  end

  def poll
    desktop_login_request = DesktopLoginRequest.find_by!(public_id: params[:public_id])
    raw_polling_token = poll_params[:polling_token]

    unless desktop_login_request.valid_polling_token?(raw_polling_token)
      raise Auth::UnauthorizedError, "Invalid desktop sign-in request."
    end

    render json: desktop_session_poll_response(desktop_login_request)
  end

  private

  def poll_params
    params.require(:desktop_session).permit(:polling_token)
  end

  def desktop_session_poll_response(desktop_login_request)
    return { desktop_session: { status: "expired" } } if desktop_login_request.expired?
    return { desktop_session: { status: "pending" } } unless desktop_login_request.approved?
    return { desktop_session: { status: "completed" } } if desktop_login_request.completed?

    desktop_login_request.update!(completed_at: Time.current)

    session_payload = Auth::SessionIssuer.call(
      user: desktop_login_request.user,
      auth_method: "desktop_browser",
      metadata: {
        "desktop_login_request_id" => desktop_login_request.public_id,
        "ip_address" => request.remote_ip,
        "user_agent" => request.user_agent
      }
    )

    {
      desktop_session: {
        status: "approved",
        session: session_payload
      }
    }
  end
end
