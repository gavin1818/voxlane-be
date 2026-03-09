require "jwt"

module Auth
  class AccessTokenVerifier
    def self.call(token)
      decoded, = JWT.decode(
        token,
        AppConfig.auth_jwt_secret,
        true,
        algorithms: [ "HS256" ],
        aud: AppConfig.auth_token_audience,
        verify_aud: true,
        iss: AppConfig.auth_token_issuer,
        verify_iss: true
      )

      decoded.deep_symbolize_keys
    rescue JWT::DecodeError => error
      raise UnauthorizedError, error.message
    end
  end
end
