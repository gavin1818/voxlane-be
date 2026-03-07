require "test_helper"

class WebSiteFlowTest < ActionDispatch::IntegrationTest
  private def with_stubbed_singleton_method(object, method_name, implementation)
    singleton_class = class << object; self; end
    method_was_defined = singleton_class.method_defined?(method_name) || singleton_class.private_method_defined?(method_name)
    original_method = object.method(method_name) if method_was_defined

    singleton_class.send(:define_method, method_name, &implementation)
    yield
  ensure
    if method_was_defined
      singleton_class.send(:define_method, method_name, original_method)
    else
      singleton_class.send(:remove_method, method_name)
    end
  end

  test "pricing page renders" do
    get pricing_path

    assert_response :success
    assert_includes response.body, "Voxlane turns fast speech into clean, ready-to-send text."
  end

  test "verify code signs user in and redirects to account" do
    with_stubbed_singleton_method(
      Auth::SupabaseOtpClient,
      :verify_code!,
      ->(email:, token:) {
        {
          "access_token" => "valid-access-token",
          "refresh_token" => "valid-refresh-token",
          "user" => { "email" => "alex@example.com" }
        }
      }
    ) do
      with_stubbed_singleton_method(
        Auth::SupabaseTokenVerifier,
        :call,
        ->(_token) {
          {
            sub: "supabase-user-1",
            email: "alex@example.com",
            user_metadata: { name: "Alex" }
          }
        }
      ) do
        post login_verify_path, params: {
          auth: {
            email: "alex@example.com",
            token: "123456"
          }
        }

        assert_redirected_to account_path
        follow_redirect!

        assert_response :success
        assert_includes response.body, "alex@example.com"
        assert_includes response.body, "Current access state"
      end
    end
  end

  test "checkout redirects authenticated users to stripe checkout" do
    stripe_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/c/pay/cs_test_123")

    with_stubbed_singleton_method(
      Auth::SupabaseOtpClient,
      :verify_code!,
      ->(email:, token:) {
        {
          "access_token" => "valid-access-token",
          "refresh_token" => "valid-refresh-token",
          "user" => { "email" => "alex@example.com" }
        }
      }
    ) do
      with_stubbed_singleton_method(
        Auth::SupabaseTokenVerifier,
        :call,
        ->(_token) {
          {
            sub: "supabase-user-2",
            email: "alex@example.com"
          }
        }
      ) do
        post login_verify_path, params: {
          auth: {
            email: "alex@example.com",
            token: "123456"
          }
        }

        with_stubbed_singleton_method(
          Billing::StripeCheckoutSessionCreator,
          :call,
          ->(user:, success_url:, cancel_url:) { stripe_session }
        ) do
          post checkout_path

          assert_redirected_to stripe_session.url
        end
      end
    end
  end
end
