require "uri"

class AppConfig
  class << self
    def auth_jwt_secret
      ENV["AUTH_JWT_SECRET"].presence || Rails.application.secret_key_base
    end

    def auth_token_issuer
      ENV.fetch("AUTH_TOKEN_ISSUER", "voxlane-auth")
    end

    def auth_token_audience
      ENV.fetch("AUTH_TOKEN_AUDIENCE", "voxlane-api")
    end

    def auth_access_token_ttl
      ENV.fetch("AUTH_ACCESS_TOKEN_TTL_MINUTES", 15).to_i.minutes
    end

    def auth_refresh_token_ttl
      ENV.fetch("AUTH_REFRESH_TOKEN_TTL_DAYS", 30).to_i.days
    end

    def password_reset_token_ttl
      ENV.fetch("PASSWORD_RESET_TOKEN_TTL_MINUTES", 30).to_i.minutes
    end

    def desktop_login_ttl
      ENV.fetch("DESKTOP_LOGIN_TTL_MINUTES", 10).to_i.minutes
    end

    def mailer_from
      ENV.fetch("MAILER_FROM", "Voxlane <support@voxlane.io>")
    end

    def google_client_id
      ENV["GOOGLE_CLIENT_ID"].to_s.strip
    end

    def google_client_secret
      ENV["GOOGLE_CLIENT_SECRET"].to_s.strip
    end

    def google_redirect_uri
      ENV["GOOGLE_REDIRECT_URI"].presence || "#{frontend_url.chomp("/")}/auth/google/callback"
    end

    def google_oauth_enabled?
      google_client_id.present? && google_client_secret.present?
    end

    def apple_service_id
      ENV["APPLE_SERVICE_ID"].to_s.strip
    end

    def apple_team_id
      ENV["APPLE_TEAM_ID"].to_s.strip
    end

    def apple_key_id
      ENV["APPLE_KEY_ID"].to_s.strip
    end

    def apple_private_key
      ENV["APPLE_PRIVATE_KEY"].to_s.gsub("\\n", "\n").strip
    end

    def apple_redirect_uri
      ENV["APPLE_REDIRECT_URI"].presence || "#{frontend_url.chomp("/")}/auth/apple/callback"
    end

    def apple_oauth_enabled?
      apple_service_id.present? &&
        apple_team_id.present? &&
        apple_key_id.present? &&
        apple_private_key.present?
    end

    def entitlement_key
      ENV.fetch("ENTITLEMENT_KEY", "pro")
    end

    def frontend_url
      ENV.fetch("FRONTEND_URL", "http://localhost:3000")
    end

    def allowed_origins
      configured = ENV.fetch("CORS_ALLOWED_ORIGINS", "")
        .split(",")
        .map(&:strip)
        .reject(&:empty?)

      ([frontend_url] + configured).map { |origin| normalize_origin(origin) }.uniq
    end

    def checkout_success_url
      ENV.fetch("STRIPE_CHECKOUT_SUCCESS_URL", "#{frontend_url}/account?checkout=success")
    end

    def checkout_cancel_url
      ENV.fetch("STRIPE_CHECKOUT_CANCEL_URL", "#{frontend_url}/pricing?checkout=cancelled")
    end

    def portal_return_url
      ENV.fetch("STRIPE_PORTAL_RETURN_URL", "#{frontend_url}/account")
    end

    def trial_days
      ENV.fetch("TRIAL_DAYS", 7).to_i
    end

    def app_name
      ENV.fetch("APP_NAME", "Voxlane")
    end

    def support_email
      ENV.fetch("SUPPORT_EMAIL", "support@voxlane.io")
    end

    def app_download_url
      ENV.fetch("APP_DOWNLOAD_URL", frontend_url)
    end

    def stripe_price_label
      ENV.fetch("STRIPE_PRICE_LABEL", "Shown at checkout")
    end

    def stripe_price_id
      ENV.fetch("STRIPE_PRO_PRICE_ID")
    end

    def sparkle_appcast_url
      ENV.fetch("SPARKLE_APPCAST_URL", "#{frontend_url}/appcast.xml")
    end

    def sparkle_latest_version
      ENV.fetch("SPARKLE_LATEST_VERSION", ENV.fetch("APP_VERSION", "1.0.0"))
    end

    def sparkle_latest_build
      ENV.fetch("SPARKLE_LATEST_BUILD", ENV.fetch("APP_BUILD", "1"))
    end

    def sparkle_download_url
      ENV.fetch("SPARKLE_DOWNLOAD_URL", app_download_url)
    end

    def sparkle_download_length
      ENV.fetch("SPARKLE_DOWNLOAD_LENGTH", "0")
    end

    def sparkle_eddsa_signature
      ENV.fetch("SPARKLE_EDDSA_SIGNATURE", "")
    end

    def sparkle_minimum_system_version
      ENV.fetch("SPARKLE_MINIMUM_SYSTEM_VERSION", "14.0")
    end

    def sparkle_release_notes_url
      ENV.fetch("SPARKLE_RELEASE_NOTES_URL", "#{frontend_url}/releases/latest")
    end

    def sparkle_release_notes_items
      ENV.fetch(
        "SPARKLE_RELEASE_NOTES_ITEMS",
        "Browser-based sign in|Stripe billing|Website checkout|Sparkle auto updates"
      ).split("|").map(&:strip).reject(&:empty?)
    end

    def sparkle_published_at
      raw_value = ENV["SPARKLE_PUBLISHED_AT"].presence
      timestamp = raw_value.present? ? Time.zone.parse(raw_value) : Time.current
      timestamp&.rfc2822 || Time.current.rfc2822
    end

    def sparkle_ready?
      sparkle_download_url.present? && sparkle_eddsa_signature.present?
    end

    def validated_return_url(candidate, fallback:)
      return fallback if candidate.blank?

      normalized = normalize_origin(candidate)
      return fallback unless allowed_origins.include?(normalized)

      candidate
    rescue URI::InvalidURIError
      fallback
    end

    private

    def normalize_origin(url)
      uri = URI.parse(url)
      raise URI::InvalidURIError, url unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

      port = if uri.port && uri.port != uri.default_port
        ":#{uri.port}"
      else
        ""
      end

      "#{uri.scheme}://#{uri.host}#{port}"
    end
  end
end
