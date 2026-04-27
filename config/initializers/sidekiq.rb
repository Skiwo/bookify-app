redis_config = {
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
}

Sidekiq.configure_server { |c| c.redis = redis_config }
Sidekiq.configure_client { |c| c.redis = redis_config }
