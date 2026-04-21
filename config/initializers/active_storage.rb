# Cache proxy-served blobs for 1 year (files are content-addressed, so safe to cache long)
Rails.application.config.active_storage.content_types_to_serve_as_binary -= ["image/svg+xml"]
Rails.application.config.active_storage.proxy_cache_control = "public, max-age=31536000, immutable"
