# Bookify → Payout Partner API v2 — rebuild plan

**Status:** plan (2026-06-14). Bookify currently integrates against an **outdated**
POP contract (the pre-reshape `/enrollment_requests` + `lines`/`rate` shape, the
`core.*` host, and the old unmasked profile). This plan brings it onto the current
**Partner API v2**.

**Delete the whole app? No.** Bookify's structure is sound — Rails 8, sensible
models (`Booking`/`BookingLine` already store money as `rate_ore` in øre),
passwordless auth, the `PopApiClient` + "API call inspector" idea are good teaching
tools. Only the **POP integration layer** is stale. This is a targeted rebuild of
that layer + the docs, not a rewrite.

The authoritative contract is POP's OpenAPI 3.1 spec (`partner-api-v2.openapi.yaml`)
and the integration guide `docs/kikkback/payout-partner-api-v2-integration.md` in
pop-core. Mirror those.

---

## 0. The deltas driving this (old → new)

| Area | Bookify today | API v2 |
|---|---|---|
| API host | `.env` / docs say `core.payoutpartner.com` | **`api.payoutpartner.com`** / `sandbox.api.payoutpartner.com` |
| App host | derived via `base_url.sub("core.","app.")` | `app.payoutpartner.com` / `sandbox.app.payoutpartner.com` (returned by POP; don't derive) |
| Onboard | `POST /enrollment_requests` `{partner_worker_id,email,callback_url}` → `enroll_url` | `POST /enroll_sessions` `{worker_id,email,return_url}` → `url` |
| Profile | top-level `enrollment_id`, **unmasked** `bank_account`, full `personal_number` | `worker_id`, masked `payout_method.bank_account_number` (`****1234`), masked `personal_number` (`DDMMYY*****`); **no `enrollment_id`** |
| Payout | `lines` with `rate` (NOK), per-line `work_started_at/ended_at/work_hours`, `group` | `work_lines` with `unit_price` (**øre**), a `duration` object, nested `sub_lines` |
| Idempotency | optional / auto | **mandatory** `idempotency_key` |
| Pref change | `manage` callback exists, no minting call | `POST /payout_method_sessions` (same handoff) |
| Auth | `Bearer` ✓ | `Bearer pk_sandbox_…/pk_live_…` ✓ (keep) |
| Deprecated cruft | `hmac_secret`, `partner_id`, connect-JWT remnants, enrollment-CRUD | none of these are in the v2 surface |

---

## 1. `app/services/pop_api_client.rb` (the core change)

### 1a. Onboarding — replace `request_enrollment`
```ruby
# was: POST /enrollment_requests {partner_worker_id, email, callback_url} → enroll_url
def start_enrollment(worker_id:, email:, return_url:, name: nil, locale: nil)
  post("/api/v2/partner/enroll_sessions", {
    worker_id: worker_id, email: email, return_url: return_url,
    name: name, locale: locale
  }.compact)
end
# response: { "id", "url", "expires_at" } — redirect the freelancer to `url`
```

### 1b. Add payout-preference session (for the existing `manage` callback)
```ruby
def start_payout_method_session(worker_id:, email:, return_url:)
  post("/api/v2/partner/payout_method_sessions",
       { worker_id: worker_id, email: email, return_url: return_url })
end
```

### 1c. Payouts — rebuild `create_payout` to the work_lines shape
`unit_price` is **øre**, so it maps directly from `BookingLine#rate_ore` (no `*100`).
```ruby
def create_payout(worker_id:, idempotency_key:, work_lines:,
                  order_reference: nil, buyer_reference: nil,
                  invoiced_on: nil, due_on: nil, external_note: nil)
  body = {
    worker_id: worker_id,
    idempotency_key: idempotency_key,           # MANDATORY — never nil
    work_lines: work_lines,                      # see builder below
    order_reference: order_reference, buyer_reference: buyer_reference,
    invoiced_on: invoiced_on, due_on: due_on, external_note: external_note
  }.compact
  post("/api/v2/partner/payouts", body)
end
```
Build `work_lines` from the booking (new helper, e.g. in `Payout` or a builder):
```ruby
# per BookingLine:
{
  occupation_code: line.occupation_code,        # optional; POP falls back to partner default
  unit_price: line.rate_ore,                     # already øre
  quantity: line.effective_hours,                # multiplier; for hourly work this is the hours count
  duration: duration_for(line),                  # { start_date, end_date, duration_hours } OR datetimes
  sub_lines: sub_lines_for(line)                 # expense/mileage/diet → see §1d
}
```
`duration_for`: time-based line → `{ start_date:, end_date:, duration_hours: line.hours }`
(hourly/timeloenn). Date-only / no hours → omit `duration_hours` (commission/honorar).
**Decide:** is `quantity` the hours and `unit_price` the hourly rate (amount =
rate × hours), or is `quantity` 1 and `duration_hours` purely informational? Pick
one and keep amount = `unit_price × quantity` correct. For hourly bookings the
clean mapping is `unit_price = rate_ore`, `quantity = hours`, and
`duration.duration_hours = hours`.

### 1d. Sub-lines (expenses/mileage/diet)
Map any non-work booking lines to `sub_lines` under their work line:
`expense` → `{ line_type:"expense", unit_price:, receipt_url: }` (receipt_url must be
a public HTTPS URL POP can fetch — host bookify's receipts publicly or skip in the
demo); `mileage` → `{ line_type:"mileage", unit_price:, quantity:, address_from:, address_to: }`;
`diet` → `{ line_type:"diet", unit_price:, quantity:, trip_type: }`.

### 1e. `app_url` fix + base_url default
```ruby
def app_url
  @credentials[:app_url].presence || ENV["POP_APP_URL"] ||
    base_url.sub("//api.", "//app.").sub("//sandbox.api.", "//sandbox.app.")
end
# base_url default stays https://sandbox.api.payoutpartner.com (already correct)
```

### 1f. Drop the legacy enrollment-CRUD methods
`list/get/delete/deactivate/reactivate_enrollment` hit `/api/v2/partner/enrollments`,
which is **not part of the v2 contract surface** (sessions + profiles + payouts +
occupation_codes). Bookify should track enrollment state in its own DB and read POP
state via `GET /profiles` / `GET /profiles/:worker_id`. Remove these methods (or, if
you keep them as a "legacy demo", clearly label them as not part of v2).

---

## 2. `app/controllers/callbacks_controller.rb` + `PopProfileExtraction`

- `#onboard`: keep the `worker_id` + `status` query handling. Drop
  `pop_enrollment_id: profile_data["enrollment_id"]` — the v2 profile has **no
  `enrollment_id`**; key everything on `worker_id`. Re-check `abandoned_worker_id`:
  the v2 flow may not emit it — treat as optional/absent.
- `extract_profile` / `sanitize_profile_data`: rewrite for the new masked shape —
  `worker_id`, `status`, `payout_preference`, `freelancer.{name,email,freelance_type,
  organization_number,personal_number(masked),address}`, `payout_method.{bank_account_number(masked),
  currency,tax_rate,tax_card_valid,frikort_amount}`. Never store these as if real
  bank/identity data; they're masked display metadata.
- `#manage`: fine as-is (`status == "updated"`); just make sure the session was
  minted via `start_payout_method_session` (§1b).

---

## 3. Models / schema

- `Enrollment`: drop or stop populating `pop_enrollment_id` (no longer returned).
  `pop_worker_id` is the join key. Keep `pop_profile_data` (now the masked shape).
- `BookingLine`: already øre-native (`rate_ore`). Add a clean mapping to the work_line
  builder; ensure `line_type` values map to v2 (`work` → a work line; `expense/mileage/
  diet/benefit/extra` → sub_lines). Confirm `time_based?`/`project_based?` →
  `duration` correctly (project-based with `total_hours` but no dates = honorar).
- `Payout`: generate a deterministic `idempotency_key` (e.g.
  `"booking-#{booking_id}-payout-#{payout.id}"`) and pass it on create. Persist it.
- `User#pop_credentials`: drop `hmac_secret` and `partner_id` (connect-JWT era —
  unused by v2). Keep `api_key`, `base_url`, `app_url`.

---

## 4. Config / env

- `.env.sample` and `.env`: `POP_BASE_URL=https://sandbox.api.payoutpartner.com`
  (not `core.*`); add `POP_APP_URL=https://sandbox.app.payoutpartner.com`; remove
  `POP_HMAC_SECRET`, `POP_PARTNER_ID`.
- Settings UI (`booker/settings/show.html.haml`): remove HMAC secret / partner-id
  fields; keep API key + (optional) base/app URL overrides; relabel any `core.*`
  copy to `api.*`.

---

## 5. Docs (these are the public teaching surface — must be correct)

- `README.md`: fix the "POP Domain Architecture" table (`api.*` not `core.*`); rewrite
  the 3 flows' sequence diagrams + request/response bodies to the v2 shapes; **replace
  the profile example** (it currently shows an *unmasked* `bank_account` and
  `personal_number` — a B-022 leak in the docs) with the masked `payout_method` shape;
  fix the curl examples' host.
- `llms.txt` and `CLAUDE.md`: update endpoint names, hosts, and shapes so the app's
  own AItooling generates correct code.

---

## 6. Tests (`spec/`)

- Update the `PopApiClient` specs/VCR cassettes (or WebMock stubs) to the new
  endpoints/shapes.
- Add coverage: enroll_sessions request shape; payout `work_lines`/`sub_lines`/
  `duration` builder (amount = unit_price × quantity); idempotency_key always present;
  masked-profile extraction.

---

## 7. Build sequence

1. `pop_api_client.rb` (§1) — the contract layer, with specs.
2. work_line builder + `BookingLine`/`Payout` mapping (§3) + idempotency.
3. callbacks + profile extraction (§2).
4. credentials/env/settings cleanup (§3 `pop_credentials`, §4).
5. remove legacy enrollment-CRUD + connect-JWT/HMAC remnants (§1f).
6. docs (§5) + tests (§6).
7. End-to-end smoke against **sandbox** (`sandbox.api.*`): mint an enroll session,
   complete onboarding in a browser on `sandbox.app.*`, fetch the masked profile,
   create a payout, confirm 201 + `status:"submitted"`, then watch `paid_out_at`.

## 8. Open decisions (confirm before/while building)

- **Enrollment CRUD:** drop entirely (recommended) vs keep as a labelled "legacy"
  demo. v2 has no such surface.
- **`quantity` vs `duration_hours`** semantics for hourly bookings (see §1c) — pick
  the amount model and document it in the README.
- **`receipt_url`** for expense sub-lines: the demo needs publicly-fetchable receipt
  URLs (POP downloads them, and rejects internal/private hosts). Either host demo
  receipts publicly or omit expense sub-lines from the demo path.
- **`abandoned_worker_id`** on callbacks: confirm whether v2 still emits it; if not,
  remove `handle_abandoned_worker`.
