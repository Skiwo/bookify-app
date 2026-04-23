Passwordless.configure do |config|
  config.default_from_address = ENV.fetch("MAILER_FROM", "no-reply@bookify.app")
  config.expires_at = -> { 24.hours.from_now }
  config.timeout_at = -> { 24.hours.from_now }
  config.sign_out_redirect_path = "/"
  config.paranoid = false

  config.success_redirect_path = lambda { |user|
    case user.role
    when "shop_owner"  then "/shop/dashboard"
    when "client"      then "/clients/dashboard"
    when "freelancer"  then "/freelancer/dashboard"
    else "/onboarding"
    end
  }
end
