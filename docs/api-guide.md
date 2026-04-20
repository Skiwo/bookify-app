# POP REST API — Integration Guide

Everything a partner needs to integrate with the POP platform: authentication, sending payouts, managing freelancers, and onboarding new workers.

**Base URL:** `https://core.payoutpartner.com/api/v2/partner`  

---

## Getting Started

### What you need

1. A **partner account** on POP (contact the POP team)
2. An **API key** — generated in the partner portal under Settings → API Keys
3. An **HMAC secret** — generated in Settings → Rotate Secret. Used to sign JWT connect tokens.

### Enable API access

API access requires the `partner_api_v2` feature flag to be enabled on your account. Contact the POP team if you get `403 Forbidden` responses.

---

## Authentication

All requests require a Bearer token in the `Authorization` header:

```bash
curl https://core.payoutpartner.com/api/v2/partner/payouts \
  -H "Authorization: Bearer YOUR_API_KEY"
```

If the key is invalid or missing:
```json
{
  "error": {
    "code": "unauthorized",
    "message": "Invalid or missing API key"
  }
}
```

---

## Error Format

All errors follow the same structure:

```json
{
  "error": {
    "code": "error_code",
    "message": "Human-readable description",
    "details": [
      { "field": "lines[0].description", "message": "can't be blank" }
    ]
  }
}
```

`details` is only present for validation errors. Common error codes:

| Code | HTTP Status | Meaning |
|------|------------|---------|
| `unauthorized` | 401 | Missing or invalid API key |
| `forbidden` | 403 | API access not enabled for your account |
| `not_found` | 404 | Resource doesn't exist |
| `validation_failed` | 422 | Invalid request parameters |
| `duplicate_order_reference` | 409 | `order_reference` already used |
| `worker_not_found` | 404 | `worker_id` not enrolled with your account |
| `conflict` | 409 | Cannot delete — resource has active invoices |
| `internal_error` | 500 | Something went wrong on our end |

---

## Pagination

List endpoints return paginated results:

```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "per_page": 25,
    "total_pages": 4,
    "total_count": 87
  }
}
```

Query parameters:

| Param | Default | Max | Description |
|-------|---------|-----|-------------|
| `page` | `1` | — | Page number |
| `per_page` | `25` | `100` | Items per page |

---

## Rate Limiting

**600 requests per minute** per API key. If exceeded, you receive `429 Too Many Requests`:

```json
{ "error": "Rate limit exceeded. Please try again later." }
```

---

## Idempotency

To safely retry failed requests without creating duplicates, pass an `idempotency_key`:

```bash
curl -X POST .../payouts \
  -d '{ "idempotency_key": "invoice-2026-04-001", ... }'
```

- If a payout with that key already exists, POP returns the existing payout (`200 OK`)
- Safe to retry on network failures
- Keys are scoped to your account

For payouts, you can also use `order_reference` as a natural idempotency key — duplicate references return `409 Conflict`.

---

## Amounts and Currency

- All amounts are in **whole NOK** (kroner) in the API — e.g. `600` means 600 NOK
- POP stores amounts internally in **øre** (1/100 NOK) but the API always works in whole NOK
- Only Norwegian Krone (NOK) is supported

---

## Onboarding a Freelancer

Before you can pay a freelancer, they need to complete a one-time setup on POP: identity verification, payout profile, and bank account.

### Step 1 — Generate a connect token

```bash
curl -X POST https://core.payoutpartner.com/api/v2/partner/connect_tokens \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "partner_worker_id": "your-internal-id-for-this-freelancer",
    "callback_url": "https://yourapp.com/onboarding-complete"
  }'
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "expires_at": "2026-04-20T15:30:00Z"
}
```

The token expires in **30 minutes**.

### Step 2 — Redirect the freelancer

Redirect the freelancer's browser to:

```
https://app.payoutpartner.com/f/connect?token=TOKEN
```

POP handles the entire onboarding experience (co-branded with your logo and colours if configured).

### Step 3 — POP calls back

When the freelancer completes onboarding, POP redirects them to your `callback_url`:

```
https://yourapp.com/onboarding-complete?worker_id=your-internal-id&status=approved
```

The `worker_id` is the same `partner_worker_id` you provided. Status is always `approved` on success.

### Step 4 — Verify the enrollment

```bash
curl https://core.payoutpartner.com/api/v2/partner/enrollments \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -G --data-urlencode "email=freelancer@example.com"
```

Or fetch by ID:
```bash
curl https://core.payoutpartner.com/api/v2/partner/enrollments/ENROLLMENT_ID \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Response:
```json
{
  "id": "uuid",
  "status": "active",
  "approved": true,
  "partner_worker_id": "your-internal-id",
  "payout_preference": "salary",
  "freelancer": {
    "email": "freelancer@example.com",
    "first_name": "Kari",
    "last_name": "Nordmann",
    "personal_number": "12345678901",
    "freelance_type": "individual",
    "bank_account_number": "12345678901",
    "address": {
      "line1": "Storgata 1",
      "postal_code": "0182",
      "city": "Oslo",
      "country": "NO"
    }
  }
}
```

`payout_preference` is either `salary` (individual, tax withheld) or `enk` (company, no tax withheld).

---

## Creating a Payout

Once a freelancer is enrolled, pay them for completed work:

```bash
curl -X POST https://core.payoutpartner.com/api/v2/partner/payouts \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "worker_id": "your-internal-id",
    "order_reference": "ORD-2026-042",
    "invoiced_on": "2026-04-15",
    "lines": [
      {
        "description": "Delivery #12345 — Oslo to Bergen",
        "line_type": "work",
        "quantity": 3,
        "rate": 600,
        "work_started_at": "2026-04-15T09:00:00",
        "work_ended_at": "2026-04-15T12:00:00"
      }
    ]
  }'
```

Response (`201 Created`):
```json
{
  "id": "uuid",
  "status": "submitted",
  "invoice_number": null,
  "amount": 1800,
  "vat": 450,
  "invoiced_on": "2026-04-15",
  "due_on": "2026-04-29",
  "order_reference": "ORD-2026-042",
  "idempotency_key": null,
  "created_at": "2026-04-15T10:00:00Z",
  "freelancer": {
    "email": "freelancer@example.com",
    "name": "Kari Nordmann",
    "enrolled": true
  },
  "lines": [ ... ]
}
```

### Payout request fields

**Invoice level:**

| Field | Required | Description |
|-------|----------|-------------|
| `worker_id` | ✅ | Your internal ID for the freelancer (`partner_worker_id`) |
| `lines` | ✅ | Array of work items (see below) |
| `order_reference` | — | Your reference. Must be unique per account. At least one of `order_reference`/`buyer_reference` required. |
| `buyer_reference` | — | Customer's reference (PO number, etc.) Defaults to your account name. |
| `invoiced_on` | — | Invoice date. Defaults to today. |
| `due_on` | — | Payment due date. Defaults to `invoiced_on + 14 days`. |
| `occupation_code` | — | Fallback occupation code for all lines. Defaults to your account default. |
| `idempotency_key` | — | Unique key for safe retries. |
| `external_note` | — | Free-text note visible on the invoice. |

**Line level:**

| Field | Required | Description |
|-------|----------|-------------|
| `description` | ✅ | Description of the work |
| `rate` | ✅ | Rate in whole NOK (e.g. `600` = 600 NOK). POP converts to øre internally. |
| `line_type` | — | `work` (default), `benefit`, `expense`, `diet` |
| `quantity` | — | Number of units. Defaults to `1`. |
| `work_started_at` | — | When work began (ISO 8601). Required for individual `work` lines. Defaults to `invoiced_on 00:00`. |
| `work_ended_at` | — | When work ended. |
| `work_hours` | — | Explicit hours worked. Max 9h per day. Defaults to 1h if neither `work_ended_at` nor `work_hours` provided. |
| `occupation_code` | — | Occupation code for this line. Overrides the invoice-level default. |
| `external_id` | — | Your own line reference. |
| `group` | — | Links non-work lines to a work line. All lines with the same `group` value are grouped. |
| `receipt_url` | — | URL to a receipt PDF or image. POP downloads and attaches it. |

### Line types

| Type | Tax withheld | Notes |
|------|-------------|-------|
| `work` | Yes | Standard billable hours |
| `benefit` | Yes | Fringe benefits |
| `expense` | No | Reimbursed costs — full amount paid out |
| `diet` | Split | Set `diet_non_taxable_unit_price` and `diet_taxable_unit_price` separately |

Organization freelancers (`payout_preference: enk`) only support `work` lines.

Every payout must have at least one `work` line. Non-work lines must use `group` to reference a work line.

### Expenses and grouped lines

```json
{
  "worker_id": "worker-1",
  "lines": [
    {
      "description": "Consultation",
      "line_type": "work",
      "rate": 1200,
      "quantity": 2,
      "group": "A"
    },
    {
      "description": "Travel reimbursement",
      "line_type": "expense",
      "rate": 450,
      "quantity": 1,
      "group": "A"
    }
  ]
}
```

---

## Listing Payouts

```bash
curl "https://core.payoutpartner.com/api/v2/partner/payouts?page=1&per_page=50" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Filter by status:
```bash
curl "https://core.payoutpartner.com/api/v2/partner/payouts?status=submitted" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Payout statuses: `draft` · `submitted` · `approved` · `published` · `resolved` · `rejected` · `nullified`

---

## Managing Enrollments

### List all enrolled freelancers

```bash
curl https://core.payoutpartner.com/api/v2/partner/enrollments \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Filter by email:
```bash
curl "https://core.payoutpartner.com/api/v2/partner/enrollments?email=freelancer@example.com" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Deactivate an enrollment (stop new payouts)

```bash
curl -X POST https://core.payoutpartner.com/api/v2/partner/enrollments/ENROLLMENT_ID/deactivate \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Reactivate

```bash
curl -X POST https://core.payoutpartner.com/api/v2/partner/enrollments/ENROLLMENT_ID/reactivate \
  -H "Authorization: Bearer YOUR_API_KEY"
```

### Delete an enrollment

Only possible when the freelancer has no active invoices.

```bash
curl -X DELETE https://core.payoutpartner.com/api/v2/partner/enrollments/ENROLLMENT_ID \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Returns `204 No Content` on success.

---

## Occupation Codes

POP uses Norwegian occupation codes (yrkeskoder) to classify work for tax reporting. Your account has a default code; you can override it per line.

```bash
curl https://core.payoutpartner.com/api/v2/partner/occupation_codes \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Response:
```json
{
  "data": [
    { "id": "uuid", "code": "2544109", "name": "Interpreter" },
    { "id": "uuid", "code": "7411101", "name": "Electrician" }
  ]
}
```

---

## Freelancer Profile

Get a freelancer's profile by `partner_worker_id`:

```bash
curl https://core.payoutpartner.com/api/v2/partner/profiles/YOUR_WORKER_ID \
  -H "Authorization: Bearer YOUR_API_KEY"
```

Use this to confirm onboarding is complete after the callback.

---

## Typical Integration Flow

```
1. Freelancer signs up on your platform
        │
        ▼
2. POST /connect_tokens  →  get JWT
        │
        ▼
3. Redirect freelancer to POP onboarding
        │
        ▼
4. POP onboards freelancer, calls back to your callback_url
        │
        ▼
5. GET /profiles/:worker_id  →  confirm enrollment
        │
        ▼
6. Freelancer completes work
        │
        ▼
7. POST /payouts  →  POP creates invoice and processes payment
        │
        ▼
8. GET /payouts?status=resolved  →  confirm payment complete
```

---

## Staging Environment

Test against the staging environment before going live:

```
Base URL:  https://rc.core.payoutpartner.com/api/v2/partner
Portal:    https://rc.app.payoutpartner.com
```

Use `111111` as the OTP code in the freelancer onboarding flow on staging.

Staging uses real Folkeregister test identities — see the POP team for test personal numbers.

---

## Support

API issues or integration questions: contact the POP team via your partner account or email support@payoutpartner.com.
