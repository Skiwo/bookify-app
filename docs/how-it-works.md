# How POP Works — Partner, Freelancer & POP Interaction

A high-level guide to how the three parties interact. Start here before reading the technical implementation docs.

---

## The Three Parties

**Partner** — A company (client of POP) that hires freelancers. They integrate POP into their platform using the REST API and JWT connect links. Examples: Kikkback, Ringli.no.

**Freelancer** — An independent worker who gets paid through POP. They may be hired by one or many partners. They can be an individual (salary) or a company (ENK/AS).

**POP** — The platform in the middle. Handles onboarding, identity verification, tax compliance, invoicing, salary calculation, and payouts.

---

## The Big Picture

```
Partner                        POP                          Freelancer
  │                             │                               │
  │  1. Partner signs up        │                               │
  │  ─────────────────────────► │                               │
  │                             │                               │
  │  2. Partner sends work      │                               │
  │  ─────────────────────────► │                               │
  │  POST /api/v2/partner/      │                               │
  │  connect_tokens             │                               │
  │  ◄───────────────────────── │                               │
  │  { token: "JWT..." }        │                               │
  │                             │                               │
  │  3. Partner redirects       │                               │
  │  freelancer to POP          │                               │
  │  ─────────────────────────────────────────────────────────► │
  │  app.payoutpartner.com/     │                               │
  │  f/connect?token=JWT        │                               │
  │                             │                               │
  │                             │  4. POP onboards freelancer   │
  │                             │  ◄───────────────────────────►│
  │                             │  (identity, profile, bank)    │
  │                             │                               │
  │                             │  Enrollment created           │
  │                             │  ◄─────────────────────────── │
  │                             │                               │
  │  5. POP calls back          │                               │
  │  ◄───────────────────────── │                               │
  │  callback_url?              │                               │
  │  worker_id=X&status=approved│                               │
  │                             │                               │
  │  6. Partner submits payout  │                               │
  │  ─────────────────────────► │                               │
  │  POST /api/v2/partner/      │                               │
  │  payouts                    │                               │
  │                             │                               │
  │                             │  7. POP processes payout      │
  │                             │  calculates salary & taxes    │
  │                             │  submits to A-melding         │
  │                             │                               │
  │                             │  8. Freelancer gets paid      │
  │                             │  ─────────────────────────── ►│
  │                             │  + salary slip               │
```

---

## Step by Step

### 1. Partner Signs Up

A partner creates an account on POP (via admin panel or self-registration at `/partners/new`). After setup they have:
- An `Account` with `account_type: team`
- An `ApiKey` for REST API access
- A `partner_hmac_secret` for signing JWT tokens
- A `partner_callback_url` where POP redirects after onboarding
- Optional: branding (logo, colors, font) for the onboarding pages

Feature flags (`partner_api_v1`, `partner_api_v2`) control which API features are available.

---

### 2. Partner Gets a Connect Token

When the partner wants to onboard a freelancer, they call:

```
POST /api/v2/partner/connect_tokens
Authorization: Bearer <api_key>

{
  "worker_id": "their-internal-id-for-this-freelancer",
  "callback_url": "https://partner.com/onboard-complete"
}
```

POP returns a signed JWT (HMAC-SHA256). The JWT contains `partner_worker_id`, `callback_url`, `partner_id`, and `exp` (30-minute expiry). It's one-time use — the JTI is recorded to prevent replays.

---

### 3. Partner Redirects the Freelancer

The partner redirects the freelancer's browser to:

```
https://app.payoutpartner.com/f/connect?token=<JWT>
```

POP decodes the token, creates a `PartnerSession`, and routes the freelancer:
- **First time** → onboarding flow
- **Returning** → manage flow (edit profile, update bank account, etc.)
- **Identity issues** → re-verify identity first, then manage

---

### 4. POP Onboards the Freelancer

The onboarding wizard runs entirely on POP (co-branded with the partner's logo and colours). It collects:

1. **Consent** — accept data processing terms
2. **Email + OTP** — verify email address
3. **Identity** — via BankID (Norway) or manual Folkeregister lookup
4. **Payout type** — Individual (salary, employer tax withheld) or Organization (ENK/AS, invoice-based)
5. **Details** — address, bank account number

All data is collected into `PartnerSession.step_data` and only saved on the final step (collect-then-save pattern — no orphaned records if the user drops out mid-flow).

The final save creates (or reuses):
- `User` + `Account`
- `Identity` (verified name, personal number, DOB)
- `FreelanceProfile` (individual or organization)
- `BankAccount`
- `Enrollment` — the link between the freelancer and the partner

An `Enrollment` uniquely links one `Account` to one `partner_account`. It holds `partner_worker_id`, `payout_preference`, and `approved` status.

---

### 5. POP Calls Back to the Partner

After successful onboarding, POP redirects the freelancer's browser to the partner's `callback_url`:

```
https://partner.com/onboard-complete?worker_id=X&status=approved
```

The partner confirms via:
```
GET /api/v2/partner/profiles/<worker_id>
```

This returns the freelancer's profile data (name, payout type, bank account, etc.).

---

### 6. Partner Submits a Payout

When the partner wants to pay a freelancer for work done, they call:

```
POST /api/v2/partner/payouts
Authorization: Bearer <api_key>

{
  "worker_id": "their-internal-id",
  "lines": [
    {
      "description": "Delivery #12345",
      "line_type": "work",
      "quantity": 3,
      "rate": 600,
      "work_started_at": "2026-04-01T09:00:00",
      "work_ended_at": "2026-04-01T12:00:00"
    }
  ],
  "invoiced_on": "2026-04-01",
  "order_reference": "ORD-2026-042"
}
```

POP creates and submits an `Invoice` in one step. The partner provides amounts in whole NOK; POP stores in øre (×100) internally.

Rate is in NOK. `work_hours` defaults to 1 if not provided. `line_type` defaults to `work`. The `occupation_code` falls back to the partner's default.

---

### 7. POP Processes the Payout

After submission POP:

1. **Validates** the invoice (dates, amounts, required fields)
2. **Calculates** the financial breakdown:
   - `amount` = total before VAT
   - `gross_salary` = `amount / (1 + employer_tax)` — individual only
   - `platform_fee_amount` = `gross_salary × platform_fee`
   - `salary_tax_amount` = `(gross_salary - platform_fee) × salary_tax`
   - `payout_amount` = what the freelancer actually receives
   - `employer_tax_amount` = POP's tax obligation as legal employer (individual only)
3. **Awaits admin approval** — admin reviews and approves via the admin panel
4. **Publishes** the invoice and sends it to the partner client (EHF or email)
5. **Pays out** to the freelancer's bank account
6. **Reports** to Skatteetaten via A-melding (Norwegian payroll authority) — individual payouts only

**Individual vs Organization payouts:**

| | Individual | Organization (ENK/AS) |
|---|---|---|
| Tax withheld | Yes — salary tax deducted | No — freelancer handles own tax |
| Employer tax | Yes — POP pays 14.1% | No |
| Platform fee | Yes — e.g. 4.9% | Varies |
| Payout | `gross_salary - fee - tax` | = `amount` |
| Reported to tax authority | Yes (A-melding) | No |
| Salary slip | Yes | No |

---

### 8. Freelancer Gets Paid and Sees Their Salary Slip

Once the payout is processed the freelancer:
- Receives the payout to their registered bank account
- Gets a **salary slip** (`SalarySlip`) showing gross, deductions, and net amount
- Can view everything in the **Freelancer Self-Service Portal** (`/f/dashboard`)

---

## Freelancer Self-Service Portal

Beyond partner-initiated flows, freelancers can log in directly to POP at:

```
https://app.payoutpartner.com/f/session/new
```

Or register independently (no partner required) at:

```
https://app.payoutpartner.com/f/register
```

In the portal they see:
- All their enrollments (across all partners)
- All bookings and payouts
- Salary slips
- Their profile and identity status
- "Manage" link → generates a JWT for each enrollment, letting them edit their profile with the partner's branding

---

## The Enrollment

The `Enrollment` record is the central link. Every meaningful interaction flows through it.

```
Account (freelancer)  ◄──── Enrollment ────► Account (partner)
                              │
                              ├── partner_worker_id  (partner's internal reference)
                              ├── payout_preference  (salary / enk)
                              ├── approved           (active or revoked)
                              ├── freelance_profile  (which profile to pay)
                              └── bank_account       (where to send money)
```

One freelancer can have multiple enrollments — one per partner, or even multiple with the same partner (individual + organization profile).

Partners can manage enrollments from the **Freelancers page** (`/p/freelancers`):
- **Add** — grant consent, create enrollment
- **Revoke** — set `approved: false`, stops new payouts
- **Details** — view status, profile, bank account, invitation history

---

## Reconciliation

Partners typically record work in their own system (with their own `external_id`). POP's **Reconciliation** view (`/p/reconciliation`) lets them cross-check:

- What the partner's system recorded (payable invoices, by `external_id`)
- What POP has as receivable invoices (from freelancers)

Discrepancies are highlighted (amount mismatch, one-sided entries, unlinked). Each line can be approved and annotated. Export as CSV.

---

## Key Concepts Summary

| Concept | What it is |
|---------|-----------|
| `Enrollment` | The link between one freelancer and one partner |
| `PartnerSession` | Server-side state for a JWT-initiated onboard/manage session |
| `Invoice` | A work invoice. Can be a payout (partner → freelancer) or a receivable (freelancer → client) |
| `SalarySlip` | Payroll document generated after an individual invoice is paid |
| `AMelding` | Norwegian payroll report submitted to Skatteetaten monthly |
| `Identity` | Verified identity via BankID or Folkeregister |
| `FreelanceProfile` | Individual or organization payout profile (bank account, address, tax rates) |
| `ApiKey` | Bearer token for REST API access |
| `partner_hmac_secret` | Shared secret for signing JWT connect tokens |

---

## Further Reading

| Document | What it covers |
|----------|---------------|
| `docs/SITE_STRUCTURE.md` | All routes and URL structure |
| `docs/partner-portal/implementation.md` | Partner portal controllers, reconciliation, auth |
| `docs/freelancer-implementation.md` | Onboarding/manage flow, self-service portal, registration |
| `docs/freelancer_connect_flow.md` | Deep-dive into all 36 onboarding permutations |
| `docs/invoice-field-reference.md` | Every Invoice and InvoiceLine field explained |
| `docs/partner-portal/spec.md` | Full feature spec with planned Phase 2 additions |
