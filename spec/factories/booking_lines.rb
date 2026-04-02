FactoryBot.define do
  factory :booking_line do
    description { "Logo design work" }
    occupation_code { "7223.14" }
    rate_ore { 60_000 }
    hours { 3.0 }
    work_date { Date.current }
    booking_type { :time_based }

    trait :project_based do
      booking_type { :project_based }
      hours { nil }
      work_date { nil }
      total_hours { 40.0 }
      work_start_date { Date.current }
      work_end_date { Date.current + 30.days }
    end
  end
end
