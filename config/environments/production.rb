require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.assume_ssl = true
  config.force_ssl = true

  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  config.i18n.fallbacks = true

  app_host = ENV.fetch("APP_HOST", "bookify.app")
  config.hosts = [app_host, ".#{app_host}"]
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }

  ses_region = ENV.fetch("AWS_SES_REGION", "eu-west-1")

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "bookify.app"), protocol: "https" }
  config.action_mailer.smtp_settings = {
    address: "email-smtp.#{ses_region}.amazonaws.com",
    port: 587,
    user_name: ENV["AWS_SES_USER"],
    password: ENV["AWS_SES_PASSWORD"],
    domain: ENV.fetch("SMTP_DOMAIN", "bookify.app"),
    authentication: :login,
    enable_starttls_auto: true
  }
end
