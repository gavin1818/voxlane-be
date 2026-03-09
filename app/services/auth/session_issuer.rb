module Auth
  class SessionIssuer
    def self.call(user:, auth_method:, metadata: {})
      new(user:, auth_method:, metadata:).call
    end

    def initialize(user:, auth_method:, metadata:)
      @user = user
      @auth_method = auth_method
      @metadata = metadata
    end

    def call
      refresh_token = TokenGenerator.call
      auth_session = user.auth_sessions.create!(
        refresh_token_digest: TokenDigest.call(refresh_token),
        expires_at: AppConfig.auth_refresh_token_ttl.from_now,
        last_used_at: Time.current,
        auth_method: auth_method,
        user_agent: metadata["user_agent"],
        ip_address: metadata["ip_address"],
        metadata: metadata
      )

      user.update!(last_seen_at: Time.current)

      SessionPayloadBuilder.call(user:, auth_session:, refresh_token:)
    end

    private

    attr_reader :user, :auth_method, :metadata
  end
end
