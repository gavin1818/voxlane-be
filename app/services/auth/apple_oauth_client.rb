require "json"
require "net/http"
require "openssl"
require "uri"
require "jwt"

module Auth
  class AppleOauthClient
    class RequestError < StandardError; end

    AUTHORIZATION_ENDPOINT = "https://appleid.apple.com/auth/authorize".freeze
    TOKEN_ENDPOINT = "https://appleid.apple.com/auth/token".freeze
    KEYS_ENDPOINT = "https://appleid.apple.com/auth/keys".freeze
    JWKS_CACHE_KEY = "auth/apple/jwks".freeze

    class << self
      def authorization_url(state:, nonce:)
        raise RequestError, "Sign in with Apple is not configured." unless AppConfig.apple_oauth_enabled?

        uri = URI.parse(AUTHORIZATION_ENDPOINT)
        uri.query = URI.encode_www_form(
          client_id: AppConfig.apple_service_id,
          redirect_uri: AppConfig.apple_redirect_uri,
          response_type: "code",
          response_mode: "form_post",
          scope: "name email",
          state: state,
          nonce: nonce
        )
        uri.to_s
      end

      def exchange_code!(code:)
        raise RequestError, "Sign in with Apple is not configured." unless AppConfig.apple_oauth_enabled?

        post_form(
          TOKEN_ENDPOINT,
          client_id: AppConfig.apple_service_id,
          client_secret: client_secret,
          code: code,
          grant_type: "authorization_code",
          redirect_uri: AppConfig.apple_redirect_uri
        )
      rescue KeyError => error
        raise RequestError, error.message
      end

      def jwks
        Rails.cache.fetch(JWKS_CACHE_KEY, expires_in: 1.hour) do
          uri = URI.parse(KEYS_ENDPOINT)
          response = Net::HTTP.get_response(uri)
          raise RequestError, "Unable to fetch Apple sign-in keys." unless response.is_a?(Net::HTTPSuccess)

          JSON.parse(response.body)
        end
      end

      private

      def client_secret
        payload = {
          iss: AppConfig.apple_team_id,
          iat: Time.current.to_i,
          exp: 180.days.from_now.to_i,
          aud: "https://appleid.apple.com",
          sub: AppConfig.apple_service_id
        }

        JWT.encode(
          payload,
          OpenSSL::PKey.read(AppConfig.apple_private_key),
          "ES256",
          kid: AppConfig.apple_key_id
        )
      rescue OpenSSL::PKey::PKeyError, JWT::EncodeError => error
        raise RequestError, "Apple sign-in is misconfigured: #{error.message}"
      end

      def post_form(url, attributes)
        uri = URI.parse(url)
        request = Net::HTTP::Post.new(uri)
        request["Accept"] = "application/json"
        request.set_form_data(attributes)
        perform(uri, request)
      end

      def perform(uri, request)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        parsed = response.body.present? ? JSON.parse(response.body) : {}
        return parsed if response.is_a?(Net::HTTPSuccess)

        message = parsed["error_description"].presence ||
          parsed["error"].presence ||
          "Apple authentication failed"

        raise RequestError, message
      end
    end
  end
end
