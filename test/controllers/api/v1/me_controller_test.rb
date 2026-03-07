require "test_helper"

class Api::V1::MeControllerTest < ActionDispatch::IntegrationTest
  test "returns unauthorized without bearer token" do
    get api_v1_me_path

    assert_response :unauthorized
  end

  test "creates or updates the current user from the supabase token" do
    get api_v1_me_path, headers: auth_headers_for(sub: "user-123", email: "founder@voxlane.io", name: "Founder")

    assert_response :success

    payload = JSON.parse(response.body)
    user = User.find_by!(supabase_uid: "user-123")

    assert_equal "founder@voxlane.io", user.email
    assert_equal "Founder", user.display_name
    assert_equal "trialing", payload.dig("entitlement", "status")
    assert_equal true, payload.dig("entitlement", "access_granted")
  end
end
