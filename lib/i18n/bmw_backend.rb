require "net/http"
require "json"

module I18n
  module Backend
    # Rails I18n backend that mirrors the i18next-http-backend approach in rs-web:
    #
    #   GET ${BMW_SERVER}/{projectId}/latest/{locale}/{namespace}
    #
    # On eager_load!:
    #   1. YAML files are loaded first (local fallback — same as I18n::Backend::Simple)
    #   2. BeMyWords translations are fetched (cached) and overlaid on top
    #
    # If BMW_SERVER / BMW_PROJECT_ID / BMW_API_KEY are not set the backend
    # behaves exactly like I18n::Backend::Simple (YAML only).
    #
    # Cache TTL: BMW_CACHE_TTL seconds (default 3600). Set 0 to disable caching
    # (useful in development when env vars are set).
    class BeMyWords < Simple
      NAMESPACES = %w[
        common pages shops skill_pages clients
        shop_admin freelancer onboarding profiles
      ].freeze

      def eager_load!
        super              # 1. load YAML files
        overlay_from_bmw  # 2. overlay live BMW translations (if configured)
      end

      private

      def overlay_from_bmw
        return unless bmw_configured?

        I18n.available_locales.each do |locale|
          NAMESPACES.each do |ns|
            flat = cached_fetch(locale, ns)
            next if flat.nil? || flat.empty?

            store_translations(locale, { ns.to_sym => unflatten(flat) }, escape: false)
            Rails.logger.debug "[BeMyWords] Loaded #{flat.size} keys for #{locale}/#{ns}"
          end
        end
      rescue => e
        Rails.logger.warn "[BeMyWords] Failed to load translations: #{e.message}. Falling back to YAML."
      end

      def cached_fetch(locale, ns)
        ttl = Integer(ENV.fetch("BMW_CACHE_TTL", 3600))

        if ttl > 0
          Rails.cache.fetch("bmw/#{locale}/#{ns}", expires_in: ttl.seconds) do
            fetch_from_api(locale, ns)
          end
        else
          fetch_from_api(locale, ns)
        end
      end

      # GET /{projectId}/latest/{locale}/{namespace}
      # Returns flat JSON: { "common.actions.back" => "Tilbake", ... }
      def fetch_from_api(locale, ns)
        uri = URI("#{ENV["BMW_SERVER"]}/#{ENV["BMW_PROJECT_ID"]}/latest/#{locale}/#{ns}")
        req = Net::HTTP::Get.new(uri)
        req["Authorization"] = "Bearer #{ENV["BMW_API_KEY"]}"
        req["Content-Type"]  = "application/json"

        res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 3, read_timeout: 5) do |http|
          http.request(req)
        end

        res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body) : nil
      rescue => e
        Rails.logger.warn "[BeMyWords] API error #{locale}/#{ns}: #{e.message}"
        nil
      end

      def bmw_configured?
        ENV["BMW_SERVER"].present? && ENV["BMW_PROJECT_ID"].present? && ENV["BMW_API_KEY"].present?
      end

      # Reverse of the flatten_keys helper in translations.rake.
      # "actions.save" => "Save"  →  { "actions" => { "save" => "Save" } }
      def unflatten(flat)
        flat.each_with_object({}) do |(dotted_key, value), acc|
          parts = dotted_key.to_s.split(".")
          parts[0..-2].reduce(acc) { |h, k| h[k] ||= {} }.tap { |h| h[parts.last] = value }
        end
      end
    end
  end
end
