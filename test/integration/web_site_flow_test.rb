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

  private def create_web_user(email:)
    User.create!(
      public_id: SecureRandom.uuid,
      email:,
      display_name: "Alex",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current,
      profile: {}
    )
  end

  private def sign_in_web_user(user)
    post login_path, params: {
      auth: {
        email: user.email,
        password: "password123"
      }
    }

    assert_redirected_to account_path
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
    assert_includes response.body, "Privacy Policy"
    assert_includes response.body, "openid, email, profile"

    get terms_path
    assert_response :success
    assert_includes response.body, "Application Terms of Service"
    assert_includes response.body, "Subscriptions, trials, and billing"
  end

  test "login pages render provider chooser and dedicated email flow" do
    get login_path
    assert_response :success
    assert_includes response.body, "Continue with Google"
    assert_includes response.body, "Continue with email"
    assert_includes response.body, "Continue with Apple"

    get login_email_path
    assert_response :success
    assert_includes response.body, "Sign in with email"
    assert_includes response.body, "Continue with email"
  end

  test "email flow reveals password step for existing users" do
    user = User.create!(
      public_id: "email-flow-user",
      email: "alex@example.com",
      display_name: "Alex",
      password: "password123",
      password_confirmation: "password123",
      email_verified_at: Time.current,
      profile: {}
    )

    post login_email_path, params: {
      auth: {
        email: user.email
      }
    }

    assert_response :success
    assert_includes response.body, "Enter your password"
    assert_includes response.body, "Forgot password?"
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

  test "authenticated users visiting login pages with a desktop request auto-approve the desktop app" do
    user = User.create!(
      public_id: "desktop-login-user",
      email: "desktop@example.com",
      display_name: "Desktop User",
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

    chooser_request, = DesktopLoginRequest.issue!
    get login_path(desktop_login: chooser_request.public_id)
    assert_redirected_to desktop_login_path(chooser_request.public_id)
    follow_redirect!

    assert_response :success
    assert_includes response.body, "Your Mac is ready."
    assert_includes response.body, user.email
    assert_equal user, chooser_request.reload.user
    assert chooser_request.approved?

    email_request, = DesktopLoginRequest.issue!
    get login_email_path(desktop_login: email_request.public_id)
    assert_redirected_to desktop_login_path(email_request.public_id)
    follow_redirect!

    assert_response :success
    assert_equal user, email_request.reload.user
    assert email_request.approved?
  end

  test "authenticated users visiting provider start routes with a desktop request skip oauth and approve immediately" do
    user = User.create!(
      public_id: "desktop-provider-user",
      email: "provider@example.com",
      display_name: "Provider User",
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

    google_request, = DesktopLoginRequest.issue!
    get google_auth_path(desktop_login: google_request.public_id)
    assert_redirected_to desktop_login_path(google_request.public_id)
    follow_redirect!

    assert_response :success
    assert_equal user, google_request.reload.user
    assert google_request.approved?

    apple_request, = DesktopLoginRequest.issue!
    get apple_auth_path(desktop_login: apple_request.public_id)
    assert_redirected_to desktop_login_path(apple_request.public_id)
    follow_redirect!

    assert_response :success
    assert_equal user, apple_request.reload.user
    assert apple_request.approved?
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
    user = create_web_user(email: "alex@example.com")
    sign_in_web_user(user)

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

  test "account page treats a trialing stripe subscription as an existing purchase" do
    user = create_web_user(email: "subscribed@example.com")
    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_test_trialing",
      livemode: false,
      metadata: {}
    )
    user.subscriptions.create!(
      billing_customer: customer,
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_subscription_id: "sub_test_trialing",
      external_price_id: "price_test_123",
      status: "trialing",
      current_period_end_at: 1.month.from_now,
      cancel_at_period_end: false,
      metadata: {}
    )

    sign_in_web_user(user)

    get account_path

    assert_response :success
    assert_includes response.body, "Pro subscribed"
    assert_includes response.body, "Manage subscription"
    assert_includes response.body, "Cancel auto-renew"
    assert_not_includes response.body, "Start Pro subscription"
  end

  test "account page refreshes the purchase state on checkout success" do
    user = create_web_user(email: "checkout-success@example.com")
    customer = user.billing_customers.create!(
      provider: BillingCustomer::PROVIDER_STRIPE,
      external_customer_id: "cus_checkout_success",
      livemode: false,
      metadata: {}
    )

    sign_in_web_user(user)

    with_stubbed_singleton_method(
      Billing::StripeCheckoutCompletionSync,
      :call,
      lambda { |user:, checkout_session_id:|
        user.subscriptions.create!(
          billing_customer: customer,
          provider: BillingCustomer::PROVIDER_STRIPE,
          external_subscription_id: "sub_checkout_success",
          external_price_id: "price_test_123",
          status: "active",
          current_period_end_at: 1.month.from_now,
          cancel_at_period_end: false,
          metadata: { "checkout_session_id" => checkout_session_id }
        ).tap do
          Entitlements::Reconciler.call(user)
        end
      }
    ) do
      get account_path(checkout: "success", session_id: "cs_test_123")
    end

    assert_response :success
    assert_includes response.body, "Payment completed. Voxlane refreshed your Pro entitlement."
    assert_includes response.body, "Your Pro access is active."
    assert_includes response.body, "Manage subscription"
    assert_not_includes response.body, "You're on the included 7-day trial."
  end

  test "cancel subscription schedules end of renewal" do
    user = create_web_user(email: "cancel@example.com")
    sign_in_web_user(user)

    cancellation = Struct.new(:current_period_end_at).new(Time.zone.parse("2026-04-09 12:00:00 UTC"))

    with_stubbed_singleton_method(
      Billing::StripeSubscriptionManager,
      :cancel_at_period_end,
      ->(user:) { cancellation }
    ) do
      patch billing_subscription_cancel_path
      assert_redirected_to account_path
      follow_redirect!
    end

    assert_response :success
    assert_includes response.body, "Subscription will end on Apr 9, 2026."
  end

  test "resume subscription re-enables renewal" do
    user = create_web_user(email: "resume@example.com")
    sign_in_web_user(user)

    with_stubbed_singleton_method(
      Billing::StripeSubscriptionManager,
      :resume,
      ->(user:) { true }
    ) do
      patch billing_subscription_resume_path
      assert_redirected_to account_path
      follow_redirect!
    end

    assert_response :success
    assert_includes response.body, "Subscription will renew automatically."
  end
end
