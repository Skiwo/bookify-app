# Seed demo data for development. Idempotent — safe to run multiple times.
#
# Usage:
#   rails db:seed
#
# Optional: set these ENV vars to pre-configure sandbox credentials:
#   SEED_POP_API_KEY, SEED_POP_HMAC_SECRET, SEED_POP_PARTNER_ID

puts "Seeding Bookify demo data..."

# ─── Helpers ────────────────────────────────────────────────────────────────

def fake_worker_id(n) = "demo-bookify-worker-%03d" % n
def fake_profile_data(email, first, last, worker_n)
  {
    "enrollment_id"    => "00000000-0000-0000-0000-%012d" % worker_n,
    "partner_worker_id"=> fake_worker_id(worker_n),
    "payout_preference"=> "salary",
    "approved"         => true,
    "status"           => "Approved",
    "freelancer"       => { "email" => email, "first_name" => first, "last_name" => last, "freelance_type" => "individual" }
  }
end

# ─── Legacy booker (existing seed — keep intact) ────────────────────────────

booker = User.find_or_create_by!(email: "demo@bookify.test") do |u|
  u.name = "Demo Booker"
  u.role = :booker
end

if ENV["SEED_POP_API_KEY"].present?
  booker.update!(
    pop_sandbox_api_key:    ENV["SEED_POP_API_KEY"],
    pop_sandbox_hmac_secret: ENV["SEED_POP_HMAC_SECRET"],
    pop_sandbox_partner_id:  ENV["SEED_POP_PARTNER_ID"]
  )
  puts "  Booker POP credentials set from ENV."
end

freelancer_legacy = User.find_or_create_by!(email: "freelancer@bookify.test") do |u|
  u.name = "Anna Hansen"
  u.role = :freelancer
end

Enrollment.find_or_create_by!(booker: booker, email: "pending@example.com") do |e|
  e.name = "Pending Freelancer"; e.status = :invited; e.invited_at = 2.days.ago
end

active_enrollment = Enrollment.find_or_initialize_by(booker: booker, email: freelancer_legacy.email)
unless active_enrollment.persisted?
  active_enrollment.assign_attributes(
    name: freelancer_legacy.name, freelancer: freelancer_legacy,
    pop_worker_id: "demo-worker-001", pop_enrollment_id: "00000000-0000-0000-0000-000000000001",
    invited_at: 7.days.ago, onboarded_at: 5.days.ago,
    pop_profile_data: fake_profile_data(freelancer_legacy.email, "Anna", "Hansen", 1)
  )
  active_enrollment.status = :invited; active_enrollment.save!
  active_enrollment.update_columns(status: Enrollment.statuses[:active])
end

unless active_enrollment.bookings.exists?
  active_enrollment.bookings.create!(description: "Website redesign", status: :draft,
    booking_lines_attributes: [{ description: "Homepage design", occupation_code: "2130112",
      booking_type: :time_based, rate_ore: 80000, hours: 8, work_date: Date.current, position: 1 }])

  active_enrollment.bookings.create!(description: "Logo design", status: :completed,
    booking_lines_attributes: [{ description: "Logo design", occupation_code: "7223.14",
      booking_type: :time_based, rate_ore: 60000, hours: 3, work_date: 3.days.ago.to_date, position: 1 }])

  [
    ["demo-payout-001", "published", 180000, 1000001, 1.week.ago],
    ["demo-payout-002", "paid",      360000, 1000002, 3.days.ago],
    ["demo-payout-003", "submitted", 570000, nil,     1.day.ago]
  ].each do |pid, status, amount, invoice_n, synced|
    b = active_enrollment.bookings.create!(description: "Consulting session", status: :paid,
      booking_lines_attributes: [{ description: "Consulting", occupation_code: "2130112",
        booking_type: :time_based, rate_ore: 90000, hours: amount / 90000, work_date: 2.weeks.ago.to_date, position: 1 }])
    b.create_payout!(pop_payout_id: pid, pop_status: status, amount_ore: amount,
      pop_invoice_number: invoice_n, pop_response: { "id" => pid, "status" => status, "amount" => amount },
      synced_at: synced)
  end
  puts "  Legacy booker bookings created."
end

# ════════════════════════════════════════════════════════════════════════════
# BOOKIFY MARKETPLACE SEEDS
# ════════════════════════════════════════════════════════════════════════════

puts "\n─── Bookify Marketplace ───"

# ─── Shop owners ────────────────────────────────────────────────────────────

owner1 = User.find_or_create_by!(email: "oslo.catering@bookify.test") { |u| u.name = "Erik Solberg";   u.role = :shop_owner }
owner2 = User.find_or_create_by!(email: "renhold.pro@bookify.test")   { |u| u.name = "Maria Lindqvist"; u.role = :shop_owner }
owner3 = User.find_or_create_by!(email: "tech.konsult@bookify.test")  { |u| u.name = "Jonas Berge";     u.role = :shop_owner }

# ─── Shops ──────────────────────────────────────────────────────────────────

shop1 = Shop.find_or_create_by!(slug: "oslo-catering") do |s|
  s.owner       = owner1
  s.name        = "Oslo Catering AS"
  s.city        = "Oslo"
  s.description = "Profesjonell catering til alle typer arrangementer. Fra intime middager til store konferanser med 500+ gjester."
  s.skill_slugs = %w[kokker bartendere servitorer cateringassistenter]
  s.visibility  = :public_shop
  s.status      = :active
  s.commission_percent = 5
  s.pop_worker_id      = fake_worker_id(10)
end

shop2 = Shop.find_or_create_by!(slug: "renhold-pro-bergen") do |s|
  s.owner       = owner2
  s.name        = "Renhold Pro Bergen"
  s.city        = "Bergen"
  s.description = "Grundig og pålitelig rengjøring for næringsliv og kontor. Godkjent av Arbeidstilsynet."
  s.skill_slugs = %w[renholdere vektere]
  s.visibility  = :public_shop
  s.status      = :active
  s.commission_percent = 7
  s.pop_worker_id      = fake_worker_id(11)
end

shop3 = Shop.find_or_create_by!(slug: "tech-konsulenter-oslo") do |s|
  s.owner       = owner3
  s.name        = "Tech Konsulenter Oslo"
  s.city        = "Oslo"
  s.description = "IT-rådgivning, utvikling og systemintegrasjon. Spesialisert på Rails, React og skyinfrastruktur."
  s.skill_slugs = %w[it-konsulenter grafikere tekstforfattere]
  s.visibility  = :public_shop
  s.status      = :active
  s.commission_percent = 8
  s.pop_worker_id      = fake_worker_id(12)
end

puts "  Shops: #{[shop1, shop2, shop3].map(&:name).join(", ")}"

# ─── Freelancers & enrollments ──────────────────────────────────────────────

freelancers = [
  { email: "anna.kokk@bookify.test",      name: "Anna Bakke",     shop: shop1, n: 20 },
  { email: "lars.barten@bookify.test",    name: "Lars Nilsen",    shop: shop1, n: 21 },
  { email: "sofie.renhold@bookify.test",  name: "Sofie Lund",     shop: shop2, n: 22 },
  { email: "thomas.it@bookify.test",      name: "Thomas Haugen",  shop: shop3, n: 23 },
  { email: "ingrid.design@bookify.test",  name: "Ingrid Voss",    shop: shop3, n: 24 },
]

freelancers.each do |f|
  user = User.find_or_create_by!(email: f[:email]) { |u| u.name = f[:name]; u.role = :freelancer }
  first, last = f[:name].split

  # Enrollment on the shop owner (they act as the booker in bookify context)
  enrollment = Enrollment.find_or_initialize_by(booker: f[:shop].owner, email: f[:email])
  unless enrollment.persisted?
    enrollment.assign_attributes(
      name: f[:name], freelancer: user,
      pop_worker_id: fake_worker_id(f[:n]),
      invited_at: 2.weeks.ago, onboarded_at: 10.days.ago,
      pop_profile_data: fake_profile_data(f[:email], first, last, f[:n])
    )
    enrollment.status = :invited; enrollment.save!
    enrollment.update_columns(status: Enrollment.statuses[:active])
  end

  # ShopMember
  ShopMember.find_or_create_by!(shop: f[:shop], enrollment: enrollment) do |m|
    m.status               = :active
    m.bookify_pop_worker_id = fake_worker_id(f[:n])
    m.invited_at           = enrollment.invited_at
    m.accepted_at          = enrollment.onboarded_at
  end

  f[:user]       = user
  f[:enrollment] = enrollment
end

puts "  Freelancers: #{freelancers.map { |f| f[:name] }.join(", ")}"

# Helper: member record for a shop
def shop_member(shop, freelancers_data, name)
  fd = freelancers_data.find { |f| f[:name] == name }
  ShopMember.find_by!(shop: shop, enrollment: fd[:enrollment])
end

# ─── Client ──────────────────────────────────────────────────────────────────

client_user = User.find_or_create_by!(email: "client@bookify.test") { |u| u.name = "Knut Andersen"; u.role = :client }

client = Client.find_or_create_by!(user: client_user) do |c|
  c.org_number  = "914994583"   # Skiwo AS
  c.org_name    = "Skiwo AS"
  c.org_address = "Karenslyst allé 2, 0278 Oslo, Norge"
  c.verified_at = 1.week.ago
end

puts "  Client: #{client.org_name} (#{client_user.email})"

# ─── Jobs ────────────────────────────────────────────────────────────────────

member_anna   = shop_member(shop1, freelancers, "Anna Bakke")
member_lars   = shop_member(shop1, freelancers, "Lars Nilsen")
member_sofie  = shop_member(shop2, freelancers, "Sofie Lund")
member_thomas = shop_member(shop3, freelancers, "Thomas Haugen")
member_ingrid = shop_member(shop3, freelancers, "Ingrid Voss")

def find_or_create_job(shop:, client:, title:, **attrs)
  shop.jobs.find_by(title: title, client: client) ||
    shop.jobs.create!(title: title, client: client, **attrs)
end

# ── Shop 1: Oslo Catering ─────────────────────────────────────────────────

# 1. Draft — request received, no quote yet
find_or_create_job(
  shop: shop1, client: client,
  title:       "Catering til bursdagsselskap 40 personer",
  description: "40 gjester, lørdag kveld, trenger 3-retters middag",
  desired_date:  2.weeks.from_now.to_date,
  desired_hours: 6,
  status:        :draft
)

# 2. Quoted — quote sent, waiting for client
j_quoted = find_or_create_job(
  shop: shop1, client: client,
  title:                "Firmafest Oslo — 80 gjester",
  description:          "Årsavslutning for tech-selskap, buffét + drinkservice",
  status:               :quoted,
  assigned_member_id:   member_anna.id,
  work_amount_ore:      1_200_000,
  commission_amount_ore: 60_000,
  quote_expires_at:     48.hours.from_now
)
unless j_quoted.quote_lines.exists?
  j_quoted.quote_lines.create!([
    { description: "Kokk (6t)",        rate_ore: 90_000, hours: 6, amount_ore: 540_000, position: 0 },
    { description: "Servitør x2 (6t)", rate_ore: 70_000, hours: 6, amount_ore: 420_000, position: 1 },
    { description: "Bartender (6t)",   rate_ore: 80_000, hours: 3, amount_ore: 240_000, position: 2 },
  ])
end

# 3. Accepted — client accepted, job starts soon
find_or_create_job(
  shop: shop1, client: client,
  title:                "Lunsj catering — ukentlig, 30 pax",
  status:               :accepted,
  assigned_member_id:   member_lars.id,
  work_amount_ore:      450_000,
  commission_amount_ore: 22_500
)

# 4. In progress
find_or_create_job(
  shop: shop1, client: client,
  title:                "Catering bryllup 100 gjester",
  description:          "Heldag, 3 kokker + 4 servitører",
  status:               :in_progress,
  assigned_member_id:   member_anna.id,
  work_amount_ore:      2_800_000,
  commission_amount_ore: 140_000,
  work_date:            Date.current,
  work_hours:           10
)

# 5. Pending confirmation — shop marked complete, waiting 48h
j_pending = find_or_create_job(
  shop: shop1, client: client,
  title:                "Firmafrokost — tirsdag",
  status:               :pending_confirmation,
  assigned_member_id:   member_lars.id,
  work_amount_ore:      360_000,
  commission_amount_ore: 18_000,
  work_date:            Date.current,
  work_hours:           4,
  confirmation_deadline_at: 36.hours.from_now
)

# 6. Disputed
j_disputed = find_or_create_job(
  shop: shop1, client: client,
  title:                "Catering konferanse — dag 2",
  status:               :disputed,
  assigned_member_id:   member_anna.id,
  work_amount_ore:      800_000,
  commission_amount_ore: 40_000,
  work_date:            3.days.ago.to_date,
  work_hours:           8
)
unless j_disputed.dispute.present?
  j_disputed.create_dispute!(
    raised_by: client_user,
    reason:    "Maten var kald og servitørene kom 45 minutter for sent. Ikke det vi avtalte."
  )
end

# 7. Invoiced — invoice sent to POP
j_invoiced = find_or_create_job(
  shop: shop1, client: client,
  title:                "Sommerfest AS Skiwo 2025",
  status:               :invoiced,
  assigned_member_id:   member_anna.id,
  work_amount_ore:      1_500_000,
  commission_amount_ore: 75_000,
  work_date:            1.week.ago.to_date,
  work_hours:           8
)
unless j_invoiced.booking.present?
  enrollment = member_anna.enrollment
  booking = enrollment.bookings.new(
    description: j_invoiced.title, status: :completed,
    invoiced_on: 1.week.ago.to_date, due_on: 1.week.ago.to_date + 14
  )
  booking.booking_lines.build(
    description: j_invoiced.title, line_type: :work, booking_type: :project_based,
    rate_ore: j_invoiced.work_amount_ore, total_hours: 1,
    work_start_date: j_invoiced.work_date, work_end_date: j_invoiced.work_date, position: 0
  )
  booking.booking_lines.build(
    description: "Commission 5% — #{shop1.name}", line_type: :commission, booking_type: :project_based,
    rate_ore: j_invoiced.commission_amount_ore, total_hours: 1,
    work_start_date: j_invoiced.work_date, work_end_date: j_invoiced.work_date, position: 1
  )
  booking.save!
  payout = booking.create_payout!(
    pop_payout_id: "bookify-demo-payout-001", pop_status: "submitted",
    amount_ore: j_invoiced.work_amount_ore + j_invoiced.commission_amount_ore,
    pop_invoice_number: 2000001,
    pop_response: { "id" => "bookify-demo-payout-001", "status" => "submitted" },
    synced_at: 1.week.ago
  )
  j_invoiced.update_columns(booking_id: booking.id)
end

# 8. Completed
j_completed = find_or_create_job(
  shop: shop1, client: client,
  title:                "Julebord 2024 — 60 gjester",
  status:               :completed,
  assigned_member_id:   member_lars.id,
  work_amount_ore:      1_100_000,
  commission_amount_ore: 55_000,
  work_date:            3.months.ago.to_date,
  work_hours:           8
)

# 9. Cancelled
find_or_create_job(
  shop: shop1, client: client,
  title:   "Avlyst: Catering til produktlansering",
  status:  :cancelled
)

puts "  Shop 1 jobs: #{shop1.jobs.group(:status).count}"

# ── Shop 2: Renhold Pro ───────────────────────────────────────────────────

find_or_create_job(
  shop: shop2, client: client,
  title:  "Kontorrengjøring — ukentlig",
  status: :draft
)

find_or_create_job(
  shop: shop2, client: client,
  title:                "Kontorrengjøring Nedre Vollgate 8",
  status:               :quoted,
  assigned_member_id:   member_sofie.id,
  work_amount_ore:      280_000,
  commission_amount_ore: 19_600,
  quote_expires_at:     24.hours.from_now
)

find_or_create_job(
  shop: shop2, client: client,
  title:                "Storvask etter oppussing",
  status:               :accepted,
  assigned_member_id:   member_sofie.id,
  work_amount_ore:      640_000,
  commission_amount_ore: 44_800
)

find_or_create_job(
  shop: shop2, client: client,
  title:                "Rengjøring konferanserom — etter arrangement",
  status:               :invoiced,
  assigned_member_id:   member_sofie.id,
  work_amount_ore:      350_000,
  commission_amount_ore: 24_500,
  work_date:            5.days.ago.to_date,
  work_hours:           5
)

puts "  Shop 2 jobs: #{shop2.jobs.group(:status).count}"

# ── Shop 3: Tech Konsulenter ──────────────────────────────────────────────

find_or_create_job(
  shop: shop3, client: client,
  title:                "Rails API-integrasjon mot POP",
  status:               :in_progress,
  assigned_member_id:   member_thomas.id,
  work_amount_ore:      3_200_000,
  commission_amount_ore: 256_000,
  work_date:            Date.current,
  work_hours:           8
)

find_or_create_job(
  shop: shop3, client: client,
  title:                "UX/UI redesign av dashboard",
  status:               :pending_confirmation,
  assigned_member_id:   member_ingrid.id,
  work_amount_ore:      1_800_000,
  commission_amount_ore: 144_000,
  work_date:            2.days.ago.to_date,
  work_hours:           8,
  confirmation_deadline_at: 12.hours.from_now
)

find_or_create_job(
  shop: shop3, client: client,
  title:                "Teknisk arkitektur-review",
  status:               :invoiced,
  assigned_member_id:   member_thomas.id,
  work_amount_ore:      2_400_000,
  commission_amount_ore: 192_000,
  work_date:            2.weeks.ago.to_date,
  work_hours:           8
)

puts "  Shop 3 jobs: #{shop3.jobs.group(:status).count}"

# ─── Summary ─────────────────────────────────────────────────────────────────

puts ""
puts "Done! Sign in at http://localhost:3000"
puts ""
puts "  Legacy booker:  demo@bookify.test"
puts "  Legacy freelancer: freelancer@bookify.test"
puts ""
puts "  ── Bookify Marketplace ──"
puts "  Client:      client@bookify.test          (Skiwo AS)"
puts ""
puts "  Shop owners:"
puts "    oslo.catering@bookify.test   → Oslo Catering AS  (5%)"
puts "    renhold.pro@bookify.test     → Renhold Pro Bergen (7%)"
puts "    tech.konsult@bookify.test    → Tech Konsulenter Oslo (8%)"
puts ""
puts "  Freelancers:"
puts "    anna.kokk@bookify.test       → Oslo Catering"
puts "    lars.barten@bookify.test     → Oslo Catering"
puts "    sofie.renhold@bookify.test   → Renhold Pro"
puts "    thomas.it@bookify.test       → Tech Konsulenter"
puts "    ingrid.design@bookify.test   → Tech Konsulenter"
puts ""
puts "  Jobs per status (all shops):"
Job.group(:status).count.sort.each do |status, count|
  puts "    %-24s %d" % [status, count]
end
