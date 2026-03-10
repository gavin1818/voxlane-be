module Web
  class SessionAuthenticator
    SessionData = Struct.new(
      :claims,
      :user,
      :entitlement,
      :auth_session,
      :auth_method,
      keyword_init: true
    )

    AUTH_SESSION_PUBLIC_ID_KEY = :web_auth_session_public_id
    AUTH_METHOD_KEY = :web_auth_method

    def initialize(session:, request:)
      @session = session
      @request = request
    end

    def call
      auth_session = AuthSession.active.find_by(public_id: session[AUTH_SESSION_PUBLIC_ID_KEY])
      return clear! if auth_session.blank?

      user = auth_session.user
      return clear! if user.blank?

      entitlement = Entitlements::Reconciler.call(user)
      user.update!(last_seen_at: Time.current)
      auth_session.update!(
        last_used_at: Time.current,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      )

      SessionData.new(
        claims: {
          sub: user.public_id,
          email: user.email,
          name: user.display_name
        },
        user: user,
        entitlement: entitlement,
        auth_session: auth_session,
        auth_method: session[AUTH_METHOD_KEY]
      )
    end

    def store!(user, auth_method: nil, metadata: {})
      auth_session = user.auth_sessions.create!(
        refresh_token_digest: Auth::TokenDigest.call(Auth::TokenGenerator.call),
        expires_at: AppConfig.auth_refresh_token_ttl.from_now,
        last_used_at: Time.current,
        auth_method: auth_method.presence || "web",
        user_agent: metadata[:user_agent],
        ip_address: metadata[:ip_address],
        metadata: {}
      )

      session[AUTH_SESSION_PUBLIC_ID_KEY] = auth_session.public_id
      if auth_method.present?
        session[AUTH_METHOD_KEY] = auth_method
      else
        session.delete(AUTH_METHOD_KEY)
      end

      auth_session
    end

    def clear!
      session.delete(AUTH_SESSION_PUBLIC_ID_KEY)
      session.delete(AUTH_METHOD_KEY)
      nil
    end

    private

    attr_reader :session, :request
  end
end
