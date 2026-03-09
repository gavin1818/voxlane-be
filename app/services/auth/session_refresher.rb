module Auth
  class SessionRefresher
    def self.call(refresh_token:)
      new(refresh_token:).call
    end

    def initialize(refresh_token:)
      @refresh_token = refresh_token
    end

    def call
      auth_session = AuthSession.active.find_by(
        refresh_token_digest: TokenDigest.call(refresh_token)
      )
      raise UnauthorizedError, "Your session expired. Sign in again to continue." unless auth_session

      new_refresh_token = TokenGenerator.call
      auth_session.update!(
        refresh_token_digest: TokenDigest.call(new_refresh_token),
        expires_at: AppConfig.auth_refresh_token_ttl.from_now,
        last_used_at: Time.current
      )
      auth_session.user.update!(last_seen_at: Time.current)

      SessionPayloadBuilder.call(
        user: auth_session.user,
        auth_session: auth_session,
        refresh_token: new_refresh_token
      )
    end

    private

    attr_reader :refresh_token
  end
end
