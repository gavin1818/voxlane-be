require "json"
require "net/http"
require "uri"

module Auth
  class GoogleOauthClient
    class RequestError < StandardError; end

    AUTHORIZATION_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth".freeze
    TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token".freeze
    USERINFO_ENDPOINT = "https://openidconnect.googleapis.com/v1/userinfo".freeze

    class << self
      def authorization_url(state:)
        raise RequestError, "Google sign-in is not configured." unless AppConfig.google_oauth_enabled?

        uri = URI.parse(AUTHORIZATION_ENDPOINT)
        uri.query = URI.encode_www_form(
          client_id: AppConfig.google_client_id,
          redirect_uri: AppConfig.google_redirect_uri,
          response_type: "code",
          scope: "openid email profile",
          access_type: "online",
          include_granted_scopes: "true",
          prompt: "select_account",
          state: state
        )

        uri.to_s
      end

      def fetch_profile!(code:)
        raise RequestError, "Google sign-in is not configured." unless AppConfig.google_oauth_enabled?

        token_response = post_form(
          TOKEN_ENDPOINT,
          client_id: AppConfig.google_client_id,
          client_secret: AppConfig.google_client_secret,
          code: code,
          grant_type: "authorization_code",
          redirect_uri: AppConfig.google_redirect_uri
        )

        access_token = token_response.fetch("access_token")
        get_json(USERINFO_ENDPOINT, "Authorization" => "Bearer #{access_token}")
      rescue KeyError => error
        raise RequestError, error.message
      end

      private

      def post_form(url, attributes)
        uri = URI.parse(url)
        request = Net::HTTP::Post.new(uri)
        request["Accept"] = "application/json"
        request.set_form_data(attributes)
        perform(uri, request)
      end

      def get_json(url, headers = {})
        uri = URI.parse(url)
        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        headers.each do |key, value|
          request[key] = value
        end
        perform(uri, request)
      end

      def perform(uri, request)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end

        parsed = response.body.present? ? JSON.parse(response.body) : {}
        return parsed if response.is_a?(Net::HTTPSuccess)

        message = parsed["error_description"].presence ||
          parsed["error"].presence ||
          "Google authentication failed"

        raise RequestError, message
      end
    end
  end
end
