module Auth
  class AppleUserResolver
    class << self
      def call(claims:, user_payload: {})
        new(claims:, user_payload:).call
      end
    end

    def initialize(claims:, user_payload:)
      @claims = claims.deep_symbolize_keys
      @user_payload = user_payload.deep_symbolize_keys
    end

    def call
      existing_identity = AuthIdentity.find_by(
        provider: AuthIdentity::PROVIDER_APPLE,
        provider_uid: claims.fetch(:sub)
      )
      return update_user!(existing_identity.user) if existing_identity

      raise AppleOauthClient::RequestError, "Apple did not return an email address." if email.blank?
      raise AppleOauthClient::RequestError, "Apple email addresses must be verified." unless email_verified?

      ActiveRecord::Base.transaction do
        user = User.find_or_initialize_by(email: email)
        user.skip_password_requirement = true
        user.display_name = resolved_name if resolved_name.present?
        user.email_verified_at ||= Time.current
        user.profile = (user.profile || {}).merge(
          "apple" => {
            "is_private_email" => private_relay_email?
          }.compact
        )
        user.save!

        user.auth_identities.find_or_create_by!(
          provider: AuthIdentity::PROVIDER_APPLE
        ) do |identity|
          identity.provider_uid = claims.fetch(:sub)
          identity.email = email
          identity.metadata = claims.except(:sub, :email, :email_verified, :nonce, :iss, :aud, :exp, :iat).deep_stringify_keys
        end

        update_user!(user)
      end
    end

    private

    attr_reader :claims, :user_payload

    def email
      claims[:email].to_s.strip.downcase.presence
    end

    def email_verified?
      claims[:email_verified] == true || claims[:email_verified] == "true"
    end

    def private_relay_email?
      claims[:is_private_email] == true || claims[:is_private_email] == "true"
    end

    def resolved_name
      return user_payload[:name].to_s.strip.presence if user_payload[:name].is_a?(String)

      name_payload = user_payload[:name].is_a?(Hash) ? user_payload[:name] : {}
      [name_payload[:firstName], name_payload[:lastName]].compact.join(" ").strip.presence
    end

    def update_user!(user)
      user.update!(
        display_name: resolved_name || user.display_name,
        email_verified_at: user.email_verified_at || Time.current,
        last_seen_at: Time.current
      )
      user
    end
  end
end
