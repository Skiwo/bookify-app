FactoryBot.define do
  factory :engagement do
    association :booker, factory: [:user, :booker]
    name { "Anna Hansen" }
    sequence(:email) { |n| "freelancer#{n}@example.com" }
    status { :invited }
    invited_at { Time.current }

    trait :active do
      association :freelancer, factory: [:user, :freelancer]
      after(:create) do |engagement|
        engagement.update_columns(
          status: Engagement.statuses[:active],
          pop_worker_id: "wk_#{SecureRandom.alphanumeric(10)}",
          onboarded_at: Time.current
        )
        engagement.reload
      end
    end

    trait :onboarding do
      status { :onboarding }
    end
  end
end
