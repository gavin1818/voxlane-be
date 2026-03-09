require "jwt"

module Auth
  class AccessTokenIssuer
    def self.call(user:, auth_session:)
      expires_at = AppConfig.auth_access_token_ttl.from_now

      payload = {
        sub: user.public_id,
        sid: auth_session.public_id,
        email: user.email,
        name: user.display_name,
        aud: AppConfig.auth_token_audience,
        iss: AppConfig.auth_token_issuer,
        iat: Time.current.to_i,
        exp: expires_at.to_i
      }

      JWT.encode(payload, AppConfig.auth_jwt_secret, "HS256")
    end
  end
end
