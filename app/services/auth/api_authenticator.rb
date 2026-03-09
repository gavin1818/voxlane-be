module Auth
  class ApiAuthenticator
    SessionData = Struct.new(:claims, :user, :auth_session, keyword_init: true)

    def self.call(token)
      new(token).call
    end

    def initialize(token)
      @token = token
    end

    def call
      claims = AccessTokenVerifier.call(token)
      auth_session = AuthSession.active.find_by(public_id: claims.fetch(:sid))
      raise UnauthorizedError, "Your session expired. Sign in again to continue." unless auth_session

      user = auth_session.user
      unless ActiveSupport::SecurityUtils.secure_compare(user.public_id, claims.fetch(:sub))
        raise UnauthorizedError, "Invalid access token"
      end

      auth_session.update!(last_used_at: Time.current)
      user.update!(last_seen_at: Time.current)

      SessionData.new(claims:, user:, auth_session:)
    rescue ActiveRecord::RecordNotFound, KeyError => error
      raise UnauthorizedError, error.message
    end

    private

    attr_reader :token
  end
end
