require "json"
require "net/http"
require "uri"

module Auth
  class SupabaseOtpClient
    class RequestError < StandardError
      attr_reader :status

      def initialize(message, status: nil)
        super(message)
        @status = status
      end
    end

    class << self
      def request_code!(email:)
        perform_request(
          path: "/auth/v1/otp",
          method: Net::HTTP::Post,
          body: {
            email: email,
            create_user: true,
            email_redirect_to: AppConfig.auth_email_redirect_url
          }
        )
      end

      def verify_code!(email:, token:)
        perform_request(
          path: "/auth/v1/verify",
          method: Net::HTTP::Post,
          body: {
            email: email,
            token: token,
            type: "email"
          }
        )
      end

      def refresh_session!(refresh_token:)
        perform_request(
          path: "/auth/v1/token?grant_type=refresh_token",
          method: Net::HTTP::Post,
          body: {
            refresh_token: refresh_token
          }
        )
      end

      private

      def perform_request(path:, method:, body:)
        uri = URI.join(ENV.fetch("SUPABASE_URL"), path)
        request = method.new(uri)
        request["Content-Type"] = "application/json"
        request["Accept"] = "application/json"
        request["apikey"] = ENV.fetch("SUPABASE_ANON_KEY")
        request.body = JSON.generate(body)

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        parsed = response.body.present? ? JSON.parse(response.body) : {}
        return parsed if response.is_a?(Net::HTTPSuccess)

        error_message = parsed["msg"].presence ||
          parsed["error_description"].presence ||
          parsed["error"].presence ||
          "Supabase auth request failed"

        raise RequestError.new(error_message, status: response.code.to_i)
      end
    end
  end
end
