Passwordless.configure do |config|
  config.default_from_address = ENV.fetch("MAILER_FROM", "no-reply@bookify.app")
  config.expires_at = -> { 15.minutes.from_now }
  config.timeout_at = -> { 30.days.from_now }
  config.sign_out_redirect_path = "/"
  config.paranoid = false

  config.success_redirect_path = lambda { |user|
    if user.freelancer?
      "/freelancer/dashboard"
    else
      "/booker/dashboard"
    end
  }
end
