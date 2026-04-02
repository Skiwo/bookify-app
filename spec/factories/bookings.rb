FactoryBot.define do
  factory :booking do
    association :enrollment, :active
    status { :draft }

    after(:build) do |booking|
      booking.booking_lines.build(attributes_for(:booking_line)) if booking.booking_lines.empty?
    end

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
