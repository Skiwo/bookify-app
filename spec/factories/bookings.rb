FactoryBot.define do
  factory :booking do
    association :engagement, :active
    description { "Logo design work" }
    occupation_code { "7223.14" }
    rate_ore { 60_000 }
    hours { 3.0 }
    work_date { Date.current }
    status { :draft }

    trait :completed do
      status { :completed }
    end

    trait :paid do
      status { :paid }
      after(:create) do |booking|
        create(:payout, booking: booking)
      end
    end
  end
end
