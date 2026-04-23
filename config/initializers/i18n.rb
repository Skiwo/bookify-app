require Rails.root.join("lib/i18n/bmw_backend")

Rails.application.configure do
  config.i18n.default_locale    = :nb
  config.i18n.available_locales = [:nb, :en]
  config.i18n.fallbacks         = { nb: :en }
  config.i18n.load_path        += Dir[Rails.root.join("config/locales/**/*.yml")]

  # Swap in the BeMyWords backend after the app is fully initialized so that
  # Rails.cache is available. Mirrors what i18next-http-backend does in rs-web:
  # fetches live translations from BMW and overlays them on top of the YAML
  # fallback. If BMW env vars are absent it behaves like the default Simple backend.
  config.after_initialize do
    I18n.backend = I18n::Backend::BeMyWords.new
  end
end
