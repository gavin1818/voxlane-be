require "test_helper"

class Api::V1::Auth::DesktopSessionsControllerTest < ActionDispatch::IntegrationTest
  test "creates a browser sign-in request" do
    post api_v1_auth_desktop_sessions_path, as: :json

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal 2, payload.dig("desktop_session", "poll_interval_seconds")
    assert_includes payload.dig("desktop_session", "verification_url"), "/desktop-login/"
  end

  test "poll returns pending before approval and approved after website approval" do
    post api_v1_auth_desktop_sessions_path, as: :json
    assert_response :success

    payload = JSON.parse(response.body)
    request_id = payload.dig("desktop_session", "request_id")
    polling_token = payload.dig("desktop_session", "polling_token")

    post poll_api_v1_auth_desktop_session_path(request_id), params: {
      desktop_session: {
        polling_token: polling_token
      }
    }, as: :json

    assert_response :success
    assert_equal "pending", JSON.parse(response.body).dig("desktop_session", "status")

    user = User.create!(
      public_id: "desktop-user",
      email: "desktop@voxlane.io",
      display_name: "Desktop User",
      skip_password_requirement: true,
      email_verified_at: Time.current,
      profile: {}
    )

    DesktopLoginRequest.find_by!(public_id: request_id).approve!(user)

    post poll_api_v1_auth_desktop_session_path(request_id), params: {
      desktop_session: {
        polling_token: polling_token
      }
    }, as: :json

    assert_response :success

    approved_payload = JSON.parse(response.body)
    assert_equal "approved", approved_payload.dig("desktop_session", "status")
    assert approved_payload.dig("desktop_session", "session", "access_token").present?
    assert_equal "desktop@voxlane.io", approved_payload.dig("desktop_session", "session", "user", "email")
  end
end
