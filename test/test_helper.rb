ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    setup do
      ENV["AUTH_JWT_SECRET"] = "test-secret"
      ENV["AUTH_TOKEN_AUDIENCE"] = "voxlane-api"
      ENV["AUTH_TOKEN_ISSUER"] = "voxlane-auth"
      ENV["FRONTEND_URL"] = "https://voxlane.io"
      ENV["CORS_ALLOWED_ORIGINS"] = "https://voxlane.io,http://localhost:3000"
      ENV["TRIAL_DAYS"] = "7"
      ENV["ENTITLEMENT_KEY"] = "pro"
      ENV["STRIPE_PRO_PRICE_ID"] = "price_test_123"
    end

    def auth_token_for(sub:, email: "user@example.com", name: "Voxlane User")
      user = User.find_or_initialize_by(public_id: sub)
      user.skip_password_requirement = true
      user.email = email
      user.display_name = name
      user.email_verified_at ||= Time.current
      user.profile ||= {}
      user.save!

      Auth::SessionIssuer.call(user:, auth_method: "test", metadata: {}).fetch(:access_token)
    end

    def auth_headers_for(sub:, email: "user@example.com", name: "Voxlane User")
      {
        "Authorization" => "Bearer #{auth_token_for(sub:, email:, name:)}"
      }
    end
  end
end
