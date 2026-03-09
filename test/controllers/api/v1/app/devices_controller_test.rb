require "test_helper"

class Api::V1::App::DevicesControllerTest < ActionDispatch::IntegrationTest
  test "registers a device for the current user" do
    post api_v1_app_devices_path,
      params: {
        device: {
          device_identifier: "device-abc",
          platform: "macos",
          app_version: "1.0.0",
          metadata: {
            language: "en"
          }
        }
      },
      headers: auth_headers_for(sub: "device-user", email: "device@voxlane.io"),
      as: :json

    assert_response :created

    user = User.find_by!(public_id: "device-user")
    device = user.devices.find_by!(device_identifier: "device-abc")

    assert_equal "macos", device.platform
    assert_equal "1.0.0", device.app_version
  end
end
