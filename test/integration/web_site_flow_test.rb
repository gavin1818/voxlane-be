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

  test "marketing pages render" do
    get root_path
    assert_response :success
    assert_includes response.body, "Voxlane"

    get pricing_path
    assert_response :success
    assert_includes response.body, "One billing home."

    get privacy_path
    assert_response :success
    assert_includes response.body, "Google OAuth or email and password"
  end

  test "email registration signs the user in and shows the account center" do
    post signup_path, params: {
      user: {
        display_name: "Alex Founder",
        email: "alex@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to account_path
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Alex Founder"
    assert_includes response.body, "Connected sign-in methods"
  end

  test "email login signs the user in and allows profile updates" do
    user = User.create!(
      public_id: "web-user",
      email: "alex@example.com",
      display_name: "Alex",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current,
      profile: {}
    )

    post login_path, params: {
      auth: {
        email: user.email,
        password: "password123"
      }
    }

    assert_redirected_to account_path

    patch account_profile_path, params: {
      profile: {
        display_name: "Alex Founder"
      }
    }

    assert_redirected_to account_path
    follow_redirect!

    assert_includes response.body, "Profile updated."
    assert_includes response.body, "Alex Founder"
  end

  test "forgot password sends a reset email" do
    User.create!(
      public_id: "password-user",
      email: "alex@example.com",
      display_name: "Alex",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current,
      profile: {}
    )

    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      post forgot_password_path, params: {
        password: {
          email: "alex@example.com"
        }
      }
    end

    assert_redirected_to login_path
    assert_includes ActionMailer::Base.deliveries.last.subject, "Reset your Voxlane password"
  end

  test "checkout redirects authenticated users to stripe checkout" do
    user = User.create!(
      public_id: "checkout-user",
      email: "alex@example.com",
      display_name: "Alex",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current,
      profile: {}
    )

    post login_path, params: {
      auth: {
        email: user.email,
        password: "password123"
      }
    }

    stripe_session = Struct.new(:id, :url).new("cs_test_123", "https://checkout.stripe.com/c/pay/cs_test_123")

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
