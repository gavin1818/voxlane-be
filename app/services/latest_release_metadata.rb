require "json"
require "net/http"
require "uri"

class LatestReleaseMetadata
  FetchError = Class.new(StandardError)

  REQUIRED_FIELDS = %w[
    app_version
    app_build
    sparkle_download_url
    sparkle_download_length
    sparkle_eddsa_signature
    sparkle_minimum_system_version
    sparkle_release_notes_url
    sparkle_published_at
  ].freeze

  class << self
    def current
      url = ENV["RELEASE_METADATA_URL"].to_s.strip
      return nil if url.blank?

      mutex.synchronize do
        return @cached_payload if cache_hit?(url)

        stale_payload = @cached_url == url ? @cached_payload : nil

        begin
          payload = fetch(url)
          @cached_url = url
          @cached_payload = payload
          @cached_at = Time.now.utc
          payload
        rescue StandardError => e
          Rails.logger.error(
            "LatestReleaseMetadata fetch failed for #{url}: #{e.class}: #{e.message}"
          )
          stale_payload
        end
      end
    end

    def reset!
      mutex.synchronize do
        @cached_url = nil
        @cached_payload = nil
        @cached_at = nil
      end
    end

    private

    def cache_hit?(url)
      return false unless @cached_payload && @cached_url == url && @cached_at

      (Time.now.utc - @cached_at) < cache_ttl_seconds
    end

    def cache_ttl_seconds
      ENV.fetch("RELEASE_METADATA_CACHE_TTL_SECONDS", 60).to_i
    end

    def fetch(url)
      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 5,
        read_timeout: 5
      ) do |http|
        http.request(request)
      end

      unless response.is_a?(Net::HTTPSuccess)
        raise FetchError, "unexpected response status #{response.code}"
      end

      normalize(JSON.parse(response.body))
    rescue JSON::ParserError, URI::InvalidURIError => e
      raise FetchError, e.message
    end

    def normalize(payload)
      normalized = {
        "app_name" => cleaned(payload["app_name"]),
        "app_version" => cleaned(payload["app_version"]),
        "app_build" => cleaned(payload["app_build"]),
        "app_download_url" => cleaned(payload["app_download_url"]),
        "sparkle_download_url" => cleaned(payload["sparkle_download_url"]),
        "sparkle_download_length" => cleaned(payload["sparkle_download_length"]),
        "sparkle_eddsa_signature" => cleaned(payload["sparkle_eddsa_signature"]),
        "sparkle_minimum_system_version" => cleaned(payload["sparkle_minimum_system_version"]),
        "sparkle_release_notes_url" => cleaned(payload["sparkle_release_notes_url"]),
        "sparkle_release_notes_items" => Array(payload["sparkle_release_notes_items"]).map { |item| cleaned(item) }.reject(&:blank?),
        "sparkle_published_at" => cleaned(payload["sparkle_published_at"]),
        "static_appcast_url" => cleaned(payload["static_appcast_url"])
      }

      normalized["app_download_url"] = normalized["sparkle_download_url"] if normalized["app_download_url"].blank?

      missing_fields = REQUIRED_FIELDS.select { |field| normalized[field].blank? }
      unless missing_fields.empty?
        raise FetchError, "missing required keys: #{missing_fields.join(', ')}"
      end

      normalized
    end

    def cleaned(value)
      value.to_s.strip
    end

    def mutex
      @mutex ||= Mutex.new
    end
  end
end
