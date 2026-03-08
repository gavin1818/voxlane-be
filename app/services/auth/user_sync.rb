module Auth
  class UserSync
    def self.call(claims)
      new(claims).call
    end

    def initialize(claims)
      @claims = claims
    end

    def call
      current_user = user
      current_user.email = claims[:email].presence || current_user.email
      current_user.display_name = resolved_display_name
      current_user.last_seen_at = Time.current
      current_user.profile = claims.deep_stringify_keys
      current_user.save!
      current_user
    end

    private

    attr_reader :claims

    def resolved_display_name
      metadata = claims[:user_metadata].is_a?(Hash) ? claims[:user_metadata] : {}
      metadata[:full_name].presence || metadata[:name].presence || user.display_name.presence || claims[:email]
    end

    def user
      @user ||= User.find_or_initialize_by(supabase_uid: claims.fetch(:sub))
    end
  end
end
