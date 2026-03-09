require "test_helper"

class Api::V1::App::EntitlementsControllerTest < ActionDispatch::IntegrationTest
  test "returns an inactive entitlement after the account trial expires" do
    user = User.create!(
      public_id: "expired-user",
      email: "expired@voxlane.io",
      display_name: "Expired",
      skip_password_requirement: true,
      email_verified_at: Time.current,
      profile: {}
    )
    user.update_columns(created_at: 14.days.ago, updated_at: Time.current)

    get api_v1_app_entitlement_path, headers: auth_headers_for(sub: "expired-user", email: "expired@voxlane.io", name: "Expired")

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal "inactive", payload.dig("entitlement", "status")
    assert_equal false, payload.dig("entitlement", "access_granted")
  end
end
