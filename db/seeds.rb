# Seed demo data for development. Idempotent — safe to run multiple times.
#
# Usage:
#   rails db:seed
#
# Optional: set these ENV vars to pre-configure sandbox credentials:
#   SEED_POP_API_KEY, SEED_POP_HMAC_SECRET, SEED_POP_PARTNER_ID

puts "Seeding Bookify demo data..."

# --- Demo Booker ---

booker = User.find_or_create_by!(email: "demo@bookify.test") do |u|
  u.name = "Demo Booker"
  u.role = :booker
end

if ENV["SEED_POP_API_KEY"].present?
  booker.update!(
    pop_sandbox_api_key: ENV["SEED_POP_API_KEY"],
    pop_sandbox_hmac_secret: ENV["SEED_POP_HMAC_SECRET"],
    pop_sandbox_partner_id: ENV["SEED_POP_PARTNER_ID"]
  )
  puts "  Booker POP credentials set from ENV."
end

# --- Demo Freelancer ---

freelancer = User.find_or_create_by!(email: "freelancer@bookify.test") do |u|
  u.name = "Anna Hansen"
  u.role = :freelancer
end

# --- Enrollment: Invited (pending) ---

Enrollment.find_or_create_by!(booker: booker, email: "pending@example.com") do |e|
  e.name = "Pending Freelancer"
  e.status = :invited
  e.invited_at = 2.days.ago
end

# --- Enrollment: Active with bookings ---

active_enrollment = Enrollment.find_or_create_by!(booker: booker, email: freelancer.email) do |e|
  e.name = freelancer.name
  e.freelancer = freelancer
  e.status = :active
  e.pop_worker_id = "demo-worker-001"
  e.pop_enrollment_id = "00000000-0000-0000-0000-000000000001"
  e.invited_at = 7.days.ago
  e.onboarded_at = 5.days.ago
  e.pop_profile_data = {
    "enrollment_id" => "00000000-0000-0000-0000-000000000001",
    "partner_worker_id" => "demo-worker-001",
    "payout_preference" => "salary",
    "approved" => true,
    "status" => "Approved",
    "freelancer" => {
      "email" => freelancer.email,
      "first_name" => "Anna",
      "last_name" => "Hansen",
      "freelance_type" => "individual"
    }
  }
end

# --- Bookings ---

unless active_enrollment.bookings.exists?
  # Draft booking
  active_enrollment.bookings.create!(
    description: "Website redesign - homepage",
    occupation_code: "2130112",
    rate_ore: 80000,
    hours: 8,
    work_date: Date.current,
    booking_type: :time_based,
    status: :draft
  )

  # Completed booking (ready to pay)
  active_enrollment.bookings.create!(
    description: "Logo design",
    occupation_code: "7223.14",
    rate_ore: 60000,
    hours: 3,
    work_date: 3.days.ago.to_date,
    booking_type: :time_based,
    status: :completed
  )

  # Project-based draft
  active_enrollment.bookings.create!(
    description: "Brand guidelines document",
    occupation_code: "7223.14",
    rate_ore: 75000,
    total_hours: 20,
    work_start_date: 1.week.ago.to_date,
    work_end_date: Date.current,
    booking_type: :project_based,
    status: :draft
  )

  # Paid bookings with payouts
  paid1 = active_enrollment.bookings.create!(
    description: "Initial consultation",
    occupation_code: "2130112",
    rate_ore: 90000,
    hours: 2,
    work_date: 2.weeks.ago.to_date,
    booking_type: :time_based,
    status: :paid
  )
  paid1.create_payout!(
    pop_payout_id: "demo-payout-001",
    pop_status: "published",
    amount_ore: 180000,
    pop_invoice_number: 1000001,
    pop_response: { "id" => "demo-payout-001", "status" => "published", "amount" => 180000 },
    synced_at: 1.week.ago
  )

  paid2 = active_enrollment.bookings.create!(
    description: "Code review session",
    occupation_code: "2130112",
    rate_ore: 90000,
    hours: 4,
    work_date: 10.days.ago.to_date,
    booking_type: :time_based,
    status: :paid
  )
  paid2.create_payout!(
    pop_payout_id: "demo-payout-002",
    pop_status: "paid",
    amount_ore: 360000,
    pop_invoice_number: 1000002,
    pop_response: { "id" => "demo-payout-002", "status" => "paid", "amount" => 360000 },
    synced_at: 3.days.ago
  )

  paid3 = active_enrollment.bookings.create!(
    description: "API integration support",
    occupation_code: "2130151",
    rate_ore: 95000,
    hours: 6,
    work_date: 1.week.ago.to_date,
    booking_type: :time_based,
    status: :paid
  )
  paid3.create_payout!(
    pop_payout_id: "demo-payout-003",
    pop_status: "submitted",
    amount_ore: 570000,
    pop_invoice_number: nil,
    pop_response: { "id" => "demo-payout-003", "status" => "submitted", "amount" => 570000 },
    synced_at: 1.day.ago
  )

  puts "  Created 6 bookings (1 draft, 1 completed, 1 project-based, 3 paid) with 3 payouts."
end

puts ""
puts "Done! Sign in at http://localhost:3000 as:"
puts "  Booker:     demo@bookify.test (magic link)"
puts "  Freelancer: freelancer@bookify.test (magic link)"
puts ""
puts "The booker has 1 invited freelancer, 1 active freelancer with bookings,"
puts "and 3 payouts in different states (submitted, published, paid)."
