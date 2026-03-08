require "test_helper"

class Auth::SupabaseOtpClientTest < ActiveSupport::TestCase
  setup do
    ENV["SUPABASE_URL"] = "https://example.supabase.co"
    ENV["SUPABASE_ANON_KEY"] = "anon-test-key"
    ENV["AUTH_EMAIL_REDIRECT_URL"] = "https://voxlane.io/login"
  end

  teardown do
    ENV.delete("AUTH_EMAIL_REDIRECT_URL")
  end

  test "request_code sends the configured email redirect url" do
    captured_request = nil
    fake_response = Object.new

    def fake_response.body
      "{}"
    end

    def fake_response.is_a?(klass)
      klass == Net::HTTPSuccess || super
    end

    fake_http = Object.new
    fake_http.define_singleton_method(:request) do |request|
      captured_request = request
      fake_response
    end

    original_start = Net::HTTP.method(:start)
    Net::HTTP.singleton_class.send(:define_method, :start) do |*, **, &block|
      block.call(fake_http)
    end

    begin
      Auth::SupabaseOtpClient.request_code!(email: "user@example.com")
    ensure
      Net::HTTP.singleton_class.send(:define_method, :start, original_start)
    end

    payload = JSON.parse(captured_request.body)

    assert_equal "user@example.com", payload["email"]
    assert_equal true, payload["create_user"]
    assert_equal "https://voxlane.io/login", payload["email_redirect_to"]
  end
end
