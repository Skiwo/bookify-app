FactoryBot.define do
  factory :payout do
    association :booking, :completed
    pop_payout_id { SecureRandom.uuid }
    pop_status { "submitted" }
    amount_ore { 180_000 }
    pop_invoice_number { "INV-2026-#{rand(1000)}" }
    pop_response { { "id" => pop_payout_id, "status" => "submitted" } }
    synced_at { Time.current }
  end
end
