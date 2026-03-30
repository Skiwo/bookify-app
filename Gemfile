source "https://rubygems.org"

ruby "~> 3.2.0"

gem "rails", "~> 8.0.3"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "haml-rails", "~> 2.1"
gem "faraday", "~> 2.7"
gem "jwt", "~> 2.7"
gem "passwordless", "~> 1.0"
gem "kaminari", "~> 1.2"
gem "dotenv-rails", groups: [:development, :test]
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "brakeman", require: false
  gem "rubocop-rails", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "webmock", "~> 3.18"
  gem "shoulda-matchers", "~> 6.0"
  gem "climate_control", "~> 1.2"
end
