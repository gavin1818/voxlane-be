module Web
  class SessionAuthenticator
    SessionData = Struct.new(
      :claims,
      :user,
      :entitlement,
      :auth_session,
      keyword_init: true
    )

    USER_ID_KEY = :web_user_id

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
        auth_session: nil
      )
    end

    def store!(user)
      session[USER_ID_KEY] = user.id
    end

    def clear!
      session.delete(USER_ID_KEY)
      nil
    end

    private

    attr_reader :session
  end
end
