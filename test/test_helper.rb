ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "jwt"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    setup do
      ENV["SUPABASE_JWT_SECRET"] = "test-secret"
      ENV["SUPABASE_JWT_AUD"] = "authenticated"
      ENV["SUPABASE_JWT_ISSUER"] = "https://supabase.test/auth/v1"
      ENV["FRONTEND_URL"] = "https://voxlane.io"
      ENV["CORS_ALLOWED_ORIGINS"] = "https://voxlane.io,http://localhost:3000"
      ENV["TRIAL_DAYS"] = "7"
      ENV["ENTITLEMENT_KEY"] = "pro"
      ENV["STRIPE_PRO_PRICE_ID"] = "price_test_123"
    end

    def auth_token_for(sub:, email: "user@example.com", name: "Voxlane User")
      payload = {
        sub: sub,
        email: email,
        aud: ENV.fetch("SUPABASE_JWT_AUD"),
        iss: ENV.fetch("SUPABASE_JWT_ISSUER"),
        user_metadata: {
          full_name: name
        }
      }

      JWT.encode(payload, ENV.fetch("SUPABASE_JWT_SECRET"), "HS256")
    end

    def auth_headers_for(sub:, email: "user@example.com", name: "Voxlane User")
      {
        "Authorization" => "Bearer #{auth_token_for(sub:, email:, name:)}"
      }
    end
  end
end
