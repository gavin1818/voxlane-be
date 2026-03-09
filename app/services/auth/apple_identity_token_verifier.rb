require "jwt"

module Auth
  class AppleIdentityTokenVerifier
    class RequestError < StandardError; end

    class << self
      def call(id_token:, nonce:)
        new(id_token:, nonce:).call
      end
    end

    def initialize(id_token:, nonce:)
      @id_token = id_token
      @nonce = nonce
    end

    def call
      decoded, = JWT.decode(
        id_token,
        nil,
        true,
        algorithms: ["RS256"],
        aud: AppConfig.apple_service_id,
        verify_aud: true,
        iss: "https://appleid.apple.com",
        verify_iss: true,
        jwks: jwks_loader
      )

      claims = decoded.deep_symbolize_keys

      if nonce.present? && claims[:nonce].to_s != nonce.to_s
        raise RequestError, "Apple sign-in could not be verified."
      end

      claims
    rescue JWT::DecodeError => error
      raise RequestError, error.message
    end

    private

    attr_reader :id_token, :nonce

    def jwks_loader
      lambda do |_options|
        JWT::JWK::Set.new(Auth::AppleOauthClient.jwks)
      end
    end
  end
end
