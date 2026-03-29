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
  end
end
