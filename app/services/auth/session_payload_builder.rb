module Auth
  class SessionPayloadBuilder
    def self.call(user:, auth_session:, refresh_token:)
      expires_at = AppConfig.auth_access_token_ttl.from_now

      {
        access_token: AccessTokenIssuer.call(user:, auth_session:),
        refresh_token: refresh_token,
        token_type: "bearer",
        expires_at: expires_at.to_i,
        expires_in: AppConfig.auth_access_token_ttl.to_i,
        user: {
          public_id: user.public_id,
          email: user.email,
          display_name: user.display_name
        }
      }
    end
  end
end
