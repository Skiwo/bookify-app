# POP Side — What Needs to Exist for Bookify

## Context

Bookify (bookify.app, Skiwo AS) is a Norwegian freelance marketplace that runs on top of
Payout Partner infrastructure. Bookify itself is a **single partner account** on POP,
owned by Payout Partner AS.

This document describes what needs to exist on the POP side before the Bookify
integration can go live.

---

## 1. Partner Account

Create one partner account for Bookify with these properties:

| Field | Value |
|---|---|
| Name | Bookify |
| Owner | Payout Partner AS |
| `partner_api_v2` | `true` |
| Callback URL | `https://bookify.app/bookify/callbacks/shop_owner` (shop owners) and `https://bookify.app/bookify/callbacks/member` (members) |
| Environment | Staging first: `https://rc.core.payoutpartner.com` |

After creating, share with the Bookify integration:
- `api_key` → `BOOKIFY_POP_API_KEY`
- `hmac_secret` → `BOOKIFY_POP_HMAC_SECRET`
- `partner_id` (UUID) → `BOOKIFY_POP_PARTNER_ID`

---

## 2. New `commission` Line Type on InvoiceLine

Bookify jobs produce one invoice per job with **two payees**:

- **Work line** (`line_type: work`) → goes to the roster member (the person who did the work)
- **Commission line** (`line_type: commission`) → goes to the shop owner (5% of job value)

The `commission` line type needs to:
- Be treated as **frilanser lønn** (same tax treatment as `work`)
- Support `payee_freelance_profile_id` to route the payout to a different freelancer
  than the invoice's primary `worker_id`
- Be included in Thursday batch alongside the work line

Example payout payload Bookify will send:

```json
{
  "worker_id": "member-pop-worker-id",
  "order_reference": "bookify-job-<uuid>",
  "buyer_reference": "123456789",
  "source_params": { "bookify_job_id": "<uuid>", "shop_id": "<uuid>" },
  "lines": [
    {
      "line_type": "work",
      "description": "Catering for 50 people",
      "rate": 9500,
      "quantity": 1,
      "work_started_at": "2026-04-21T08:00:00Z",
      "work_ended_at": "2026-04-21T17:00:00Z",
      "group": "job-work"
    },
    {
      "line_type": "commission",
      "description": "Commission 5% — Oslo Catering",
      "rate": 500,
      "quantity": 1,
      "payee_freelance_profile_id": "shop-owner-pop-worker-id",
      "group": "job-work"
    }
  ]
}
```

---

## 3. `payee_freelance_profile_id` on InvoiceLine

Each invoice line needs an optional `payee_freelance_profile_id` field that:
- Accepts a `partner_worker_id` (the same ID used in connect_tokens)
- Routes that line's payment to a different enrolled freelancer
- Is used exclusively on `commission` lines in Bookify's case
- Must refer to a freelancer enrolled under the same partner account

---

## 4. `source_params` JSONB on Invoice

Each invoice needs an optional `source_params` field:
- JSONB, stored as-is
- Used by Bookify for traceability: `{ bookify_job_id, shop_id }`
- No validation required, just stored and returned in API responses

---

## 5. connect_tokens Callback Behaviour

When a shop owner or roster member completes POP onboarding, POP calls back to:

```
GET <callback_url>?worker_id=<partner_worker_id>&status=approved
```

The `callback_url` is set per connect_token when Bookify generates the JWT:
- Shop owner callback: `https://bookify.app/bookify/callbacks/shop?shop_id=<shop_uuid>`
- Member callback: `https://bookify.app/bookify/callbacks/member?token=<invitation_token>`

Both need `worker_id` and `status` in the query string — this is standard behaviour,
just confirming both URLs will receive these params.

---

## 6. Staging / Local Testing

For local development Bookify runs at `http://localhost:3003`.
Callbacks won't be reachable externally, so we'll need either:
- A local POP instance that can call back to localhost, OR
- A way to manually trigger the callback in admin (`admin.localhost:3001`)

Confirm: is there an admin action to manually fire the onboarding callback
for a given `partner_worker_id`? This would unblock local testing.

---

## Summary Checklist

- [ ] Create Bookify partner account on staging POP, share credentials
- [ ] Implement `commission` line type (frilanser lønn, supports `payee_freelance_profile_id`)
- [ ] Implement `payee_freelance_profile_id` on invoice lines
- [ ] Implement `source_params` JSONB on invoices
- [ ] Confirm callback URL format (`worker_id` + `status` in query string)
- [ ] Confirm local testing path (admin-triggered callback or ngrok)
