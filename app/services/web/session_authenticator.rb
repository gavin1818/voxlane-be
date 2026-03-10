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

    USER_ID_KEY = :web_user_id
    AUTH_METHOD_KEY = :web_auth_method

    def initialize(session:)
      @session = session
    end

    def call
      user = User.find_by(id: session[USER_ID_KEY])
      return clear! if user.blank?

      entitlement = Entitlements::Reconciler.call(user)
      user.update!(last_seen_at: Time.current)

      SessionData.new(
        claims: {
          sub: user.public_id,
          email: user.email,
          name: user.display_name
        },
        user: user,
        entitlement: entitlement,
        auth_session: nil,
        auth_method: session[AUTH_METHOD_KEY]
      )
    end

    def store!(user, auth_method: nil)
      session[USER_ID_KEY] = user.id
      if auth_method.present?
        session[AUTH_METHOD_KEY] = auth_method
      else
        session.delete(AUTH_METHOD_KEY)
      end
    end

    def clear!
      session.delete(USER_ID_KEY)
      session.delete(AUTH_METHOD_KEY)
      nil
    end

    private

    attr_reader :session
  end
end
