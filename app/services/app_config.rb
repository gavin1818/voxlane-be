require "uri"

class AppConfig
  class << self
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

    def stripe_price_id
      ENV.fetch("STRIPE_PRO_PRICE_ID")
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
