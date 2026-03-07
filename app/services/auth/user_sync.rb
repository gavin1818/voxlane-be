module Auth
  class UserSync
    def self.call(claims)
      new(claims).call
    end

    def initialize(claims)
      @claims = claims
    end

    def call
      user = User.find_or_initialize_by(supabase_uid: claims.fetch(:sub))
      user.email = claims[:email].presence || user.email
      user.display_name = resolved_display_name
      user.last_seen_at = Time.current
      user.profile = claims.deep_stringify_keys
      user.save!
      user
    end

    private

    attr_reader :claims

    def resolved_display_name
      metadata = claims[:user_metadata].is_a?(Hash) ? claims[:user_metadata] : {}
      metadata[:full_name].presence || metadata[:name].presence || claims[:email]
    end
  end
end
