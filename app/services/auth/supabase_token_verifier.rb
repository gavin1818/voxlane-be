require "jwt"
require "net/http"
require "uri"

module Auth
  class SupabaseTokenVerifier
    JWKS_CACHE_KEY = "auth/supabase/jwks"

    def self.call(token)
      new(token).call
    end

    def initialize(token)
      @token = token
    end

    def call
      payload = if jwt_secret.present?
        decode_with_shared_secret
      else
        decode_with_jwks
      end

      payload.deep_symbolize_keys
    rescue JWT::DecodeError, KeyError => error
      raise UnauthorizedError, error.message
    end

    private

    attr_reader :token

    def decode_with_shared_secret
      decoded, = JWT.decode(
        token,
        jwt_secret,
        true,
        algorithms: ["HS256"],
        aud: audience,
        verify_aud: audience.present?,
        iss: issuer,
        verify_iss: issuer.present?
      )
      decoded
    end

    def decode_with_jwks
      decoded, = JWT.decode(
        token,
        nil,
        true,
        algorithms: ["RS256"],
        aud: audience,
        verify_aud: audience.present?,
        iss: issuer,
        verify_iss: issuer.present?,
        jwks: jwks_loader
      )
      decoded
    end

    def jwks_loader
      lambda do |_options|
        JWT::JWK::Set.new(
          Rails.cache.fetch(JWKS_CACHE_KEY, expires_in: 1.hour) do
            uri = URI.parse(jwks_url)
            response = Net::HTTP.get_response(uri)
            raise UnauthorizedError, "Unable to fetch Supabase JWKS" unless response.is_a?(Net::HTTPSuccess)

            JSON.parse(response.body)
          end
        )
      end
    end

    def issuer
      ENV["SUPABASE_JWT_ISSUER"].presence || (supabase_url.present? ? "#{supabase_url}/auth/v1" : nil)
    end

    def audience
      ENV["SUPABASE_JWT_AUD"].presence
    end

    def jwks_url
      ENV["SUPABASE_JWKS_URL"].presence || "#{supabase_url || raise(KeyError, 'key not found: \"SUPABASE_URL\"')}/auth/v1/.well-known/jwks.json"
    end

    def jwt_secret
      ENV["SUPABASE_JWT_SECRET"].presence
    end

    def supabase_url
      ENV["SUPABASE_URL"].presence
    end
  end
end
