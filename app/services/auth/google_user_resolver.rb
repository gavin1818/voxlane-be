module Auth
  class GoogleUserResolver
    def self.call(profile)
      new(profile).call
    end

    def initialize(profile)
      @profile = profile.deep_symbolize_keys
    end

    def call
      raise GoogleOauthClient::RequestError, "Google did not return an email address." if email.blank?
      raise GoogleOauthClient::RequestError, "Google email addresses must be verified." unless email_verified?

      existing_identity = AuthIdentity.find_by(
        provider: AuthIdentity::PROVIDER_GOOGLE,
        provider_uid: profile.fetch(:sub)
      )
      return update_user!(existing_identity.user) if existing_identity

      ActiveRecord::Base.transaction do
        user = User.find_or_initialize_by(email: email)
        user.skip_password_requirement = true
        user.display_name = profile[:name].presence || user.display_name
        user.email_verified_at ||= Time.current
        user.profile = user.profile.merge(
          "google" => profile.slice(:picture, :locale, :given_name, :family_name).compact
        )
        user.save!

        user.auth_identities.find_or_create_by!(
          provider: AuthIdentity::PROVIDER_GOOGLE
        ) do |identity|
          identity.provider_uid = profile.fetch(:sub)
          identity.email = email
          identity.metadata = profile.except(:sub, :email, :email_verified)
        end

        update_user!(user)
      end
    end

    private

    attr_reader :profile

    def email
      profile[:email].to_s.strip.downcase.presence
    end

    def email_verified?
      profile[:email_verified] == true || profile[:email_verified] == "true"
    end

    def update_user!(user)
      user.update!(
        display_name: profile[:name].presence || user.display_name,
        email_verified_at: user.email_verified_at || Time.current,
        last_seen_at: Time.current
      )
      user
    end
  end
end
