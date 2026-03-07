module Web
  class SessionAuthenticator
    SessionData = Struct.new(
      :claims,
      :user,
      :entitlement,
      :access_token,
      :refresh_token,
      keyword_init: true
    )

    ACCESS_TOKEN_KEY = :supabase_access_token
    REFRESH_TOKEN_KEY = :supabase_refresh_token
    EMAIL_KEY = :supabase_user_email

    def initialize(session:)
      @session = session
    end

    def call
      access_token = session[ACCESS_TOKEN_KEY]
      refresh_token = session[REFRESH_TOKEN_KEY]
      return nil if access_token.blank?

      claims, current_access_token, current_refresh_token = verified_session(
        access_token: access_token,
        refresh_token: refresh_token
      )

      user = Auth::UserSync.call(claims)
      entitlement = Entitlements::Reconciler.call(user)

      SessionData.new(
        claims: claims,
        user: user,
        entitlement: entitlement,
        access_token: current_access_token,
        refresh_token: current_refresh_token
      )
    rescue Auth::UnauthorizedError, Auth::SupabaseOtpClient::RequestError
      clear!
      nil
    end

    def store!(payload)
      access_token = payload_value(payload, "access_token")
      refresh_token = payload_value(payload, "refresh_token")
      raise Auth::UnauthorizedError, "Missing Supabase access token" if access_token.blank? || refresh_token.blank?

      session[ACCESS_TOKEN_KEY] = access_token
      session[REFRESH_TOKEN_KEY] = refresh_token
      session[EMAIL_KEY] = payload_value(user_payload(payload), "email")
    end

    def clear!
      session.delete(ACCESS_TOKEN_KEY)
      session.delete(REFRESH_TOKEN_KEY)
      session.delete(EMAIL_KEY)
    end

    def email
      session[EMAIL_KEY]
    end

    private

    attr_reader :session

    def verified_session(access_token:, refresh_token:)
      claims = Auth::SupabaseTokenVerifier.call(access_token)
      [claims, access_token, refresh_token]
    rescue Auth::UnauthorizedError
      raise if refresh_token.blank?

      refreshed_session = Auth::SupabaseOtpClient.refresh_session!(refresh_token: refresh_token)
      store!(refreshed_session)

      current_access_token = session[ACCESS_TOKEN_KEY]
      current_refresh_token = session[REFRESH_TOKEN_KEY]
      claims = Auth::SupabaseTokenVerifier.call(current_access_token)
      [claims, current_access_token, current_refresh_token]
    end

    def user_payload(payload)
      payload_value(payload, "user") || {}
    end

    def payload_value(payload, key)
      payload[key] || payload[key.to_sym]
    end
  end
end
