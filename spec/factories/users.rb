FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    role { :booker }

    trait :booker do
      role { :booker }
      name { "Test Booker" }
    end

    trait :freelancer do
      role { :freelancer }
      name { "Test Freelancer" }
    end

    trait :pop_configured do
      pop_sandbox_api_key { "test-api-key" }
      pop_sandbox_hmac_secret { "test-hmac-secret" }
      pop_sandbox_partner_id { "test-partner-id" }
    end
  end
end
