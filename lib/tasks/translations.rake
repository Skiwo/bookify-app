require "net/http"
require "json"
require "yaml"
require_relative "../i18n/bmw_backend"

# BeMyWords sync/pull for Bookify Rails app.
#
# Mirrors the pattern from rs-web/scripts/sync-translations.mjs:
#   sync  — flattens YAML locale keys, PUTs them to BeMyWords
#   pull  — GETs translations from BeMyWords, writes back to YAML
#
# Env vars:
#   BMW_SERVER      - BeMyWords API base URL
#   BMW_PROJECT_ID  - Project UUID
#   BMW_API_KEY     - API token
#   BMW_SOURCE_LANG - Source language pushed during sync (default: "en")

namespace :translations do
  SOURCE_LANG  = ENV.fetch("BMW_SOURCE_LANG", "en")
  LOCALES_DIR  = Rails.root.join("config/locales")

  desc "Clear BeMyWords translation cache — next request re-fetches from BMW"
  task refresh: :environment do
    I18n::Backend::BeMyWords::NAMESPACES.each do |ns|
      I18n.available_locales.each do |locale|
        key = "bmw/#{locale}/#{ns}"
        Rails.cache.delete(key)
        puts "  Cleared: #{key}"
      end
    end
    puts "Done. Translations will be re-fetched from BeMyWords on next use."
  end

  # Top-level YAML keys treated as namespaces (mirrors rs-web namespace concept).
  NAMESPACES = %w[common pages shops skill_pages clients shop_admin freelancer onboarding profiles].freeze

  desc "Sync translation keys to BeMyWords (source: #{SOURCE_LANG})"
  task sync: :environment do
    base_url, project_id, api_key = bmw_credentials
    unless base_url
      warn "  BMW env vars not set — skipping sync."
      next
    end

    puts "Syncing translation keys to BeMyWords..."
    puts "  Server:  #{base_url}"
    puts "  Project: #{project_id}"
    puts "  Source:  #{SOURCE_LANG}\n\n"

    source_yml = load_locale(SOURCE_LANG)
    unless source_yml
      warn "  #{SOURCE_LANG}.yml not found — aborting."
      next
    end

    NAMESPACES.each do |ns|
      keys = source_yml.dig(SOURCE_LANG, ns)
      next warn "  [#{ns}] Not found in #{SOURCE_LANG}.yml — skipping" unless keys

      flat = flatten_keys(keys)
      puts "  [#{ns}] #{flat.size} keys"

      report = bmw_put(base_url, project_id, api_key, SOURCE_LANG, ns, flat)
      if report
        s = report["summary"] || {}
        puts "    Created: #{s["created"]}, Hidden: #{s["hidden"]}, Unhidden: #{s["unhidden"]}, Unchanged: #{s["unchanged"]}"
        puts "    New: #{report["created"].join(", ")}" if report["created"]&.any?
      end
      puts
    end

    puts "Sync complete."
  end

  desc "Pull translations from BeMyWords and write to config/locales/<lang>.yml"
  task :pull, [:lang] => :environment do |_, args|
    base_url, project_id, api_key = bmw_credentials
    unless base_url
      warn "  BMW env vars not set — skipping pull."
      next
    end

    langs = args[:lang] ? [args[:lang]] : I18n.available_locales.map(&:to_s)

    puts "Pulling translations from BeMyWords..."
    puts "  Server:  #{base_url}"
    puts "  Project: #{project_id}\n\n"

    langs.each do |lang|
      puts "  [#{lang}]"
      merged = { lang => {} }

      NAMESPACES.each do |ns|
        flat = bmw_get(base_url, project_id, api_key, lang, ns)
        next warn "    [#{ns}] Pull failed — skipping" unless flat

        merged[lang][ns] = unflatten_keys(flat)
        puts "    [#{ns}] #{flat.size} keys"
      end

      out_path = LOCALES_DIR.join("#{lang}.yml")
      File.write(out_path, merged.to_yaml(line_width: -1))
      puts "    Written → #{out_path}\n\n"
    end

    puts "Pull complete."
  end

  # ─── Helpers ──────────────────────────────────────────────────────────────

  def bmw_credentials
    base_url   = ENV["BMW_SERVER"].presence
    project_id = ENV["BMW_PROJECT_ID"].presence
    api_key    = ENV["BMW_API_KEY"].presence
    return nil unless base_url && project_id && api_key
    [base_url, project_id, api_key]
  end

  def load_locale(lang)
    path = LOCALES_DIR.join("#{lang}.yml")
    return nil unless File.exist?(path)
    YAML.safe_load_file(path)
  end

  # Flatten nested hash to dot-separated keys.
  # { "common" => { "actions" => { "save" => "Save" } } }
  # → { "actions.save" => "Save" }
  def flatten_keys(hash, prefix = nil)
    hash.each_with_object({}) do |(k, v), acc|
      key = prefix ? "#{prefix}.#{k}" : k.to_s
      if v.is_a?(Hash)
        acc.merge!(flatten_keys(v, key))
      else
        acc[key] = v.to_s
      end
    end
  end

  # Reverse of flatten_keys.
  def unflatten_keys(flat)
    flat.each_with_object({}) do |(key, value), acc|
      parts = key.split(".")
      parts[0..-2].reduce(acc) { |h, k| h[k] ||= {} }.tap { |h| h[parts.last] = value }
    end
  end

  def bmw_put(base_url, project_id, api_key, lang, namespace, flat_keys)
    uri  = URI("#{base_url}/api/sync/#{project_id}/latest/#{lang}/#{namespace}")
    body = { translations: flat_keys, dynamic_key_prefixes: [] }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    req  = Net::HTTP::Put.new(uri, "Content-Type" => "application/json", "Authorization" => "Bearer #{api_key}")
    req.body = body

    res = http.request(req)
    res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body) : warn("    HTTP #{res.code} — #{res.body}")
  rescue => e
    warn "    Error: #{e.message}"
    nil
  end

  def bmw_get(base_url, project_id, api_key, lang, namespace)
    # Same path as i18next loadPath: ${server}/${projectId}/latest/${lng}/${ns}
    uri = URI("#{base_url}/#{project_id}/latest/#{lang}/#{namespace}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    req  = Net::HTTP::Get.new(uri, "Authorization" => "Bearer #{api_key}")

    res = http.request(req)
    res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body) : warn("    HTTP #{res.code}")
  rescue => e
    warn "    Error: #{e.message}"
    nil
  end
end
