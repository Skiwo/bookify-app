# Bookify Phase 2 — Progress Tracker

Last updated: 2026-04-23

Reference: `docs/bookify-plan-presentation.html` (v2, April 2026)

---

## DONE

- [x] Shop model (public/private, skills, commission, avatar, slug)
- [x] Shop lifecycle (active / paused / closed / reopen)
- [x] Client registration (org_number, org_name, org_address, verified_at)
- [x] Job lifecycle — 10 statuses (draft → quoted → accepted → in_progress → pending_confirmation → disputed → invoiced → paid → completed → cancelled)
- [x] Quote flow (rate x hours, 72h expiry, assigned member, auto commission calc)
- [x] Client accept / decline quote
- [x] 3-party chat — real-time via ActionCable + Turbo Stream
- [x] Chat read receipts (SVG checkmarks, real-time update via ActionCable)
- [x] Chat online/offline indicator (last_online_at, green/grey dot)
- [x] Chat file attachments (PNG, JPG, PDF up to 5 MB)
- [x] Chat voice messages (MediaRecorder, custom audio player)
- [x] Chat message grouping (consecutive messages from same sender)
- [x] Chat date dividers (Today / Yesterday / weekday / full date)
- [x] Chat "New messages" divider with 3s delayed mark-as-read
- [x] Chat sender name — shop name for shop-side, client name for client-side
- [x] Dual completion confirmation (shop_completed_at + client_completed_at → auto invoice)
- [x] InvoicingService → POP API (work line + commission line)
- [x] Freelancer/member POP onboarding (enrollment states, callbacks, profile sync)
- [x] Private shop — invitation gating (token-based, 7-day expiry)
- [x] Public shop listing (/shops) with search by city + skill (ILIKE)
- [x] Skill category pages (/nb/no/:skill) with 24 supported skills
- [x] Color palette — Blue (#2563EB) supply side, Amber (#D97706) demand side, Indigo (#4F46E5) brand
- [x] User profiles with avatar upload (/profile/edit)
- [x] User avatar in navbar (all layouts)
- [x] Shop avatar on shop cards and chat header
- [x] Active Storage UUID fix for polymorphic attachments
- [x] Chat message pagination (last 50 + "Load earlier" link)
- [x] Active Storage proxy mode with browser caching (1yr immutable)
- [x] N+1 prevention — includes(:sender, file_attachment: :blob) on messages
- [x] Role-based layout selection (shop/client/freelancer/booker)
- [x] Role-based redirect after login
- [x] Active navbar tab indicator (white underline, all layouts)
- [x] Amount input in NOK (auto convert to øre for POP)
- [x] Skill tags — comma-separated input, lowercase normalization, ILIKE search
- [x] Quote line items (activities) — QuoteLine model, Stimulus controller, add/remove UI, auto-calc, invoicing service sends each line as separate work item to POP
- [x] Shop admin dispute view — see dispute reason, respond (respond! / resolve! + UI in shop_admin/jobs/show)
- [x] Dispute resolution workflow — admin can respond and resolve, system message posted to chat on each action
- [x] Shop page URL structure — `/nb/no/a/:slug` in place; legacy `/shops/:slug` → redirect; `/nb/no/shops` for listing

---

## PARTIALLY DONE

### BRREG verification
- [x] Client provides org_number (9-digit format validation)
- [x] Sets verified_at on registration
- [x] Actual BRREG API call to verify org exists and is active (BrregService via Faraday; checks slettedato/konkurs/underAvvikling; auto-fills org_name + org_address from registry; Stimulus lookup on keystroke)
- [x] Re-check before each invoice — BrregService called in InvoicingService#validate!; fails with "try again later" if BRREG is down

### Dispute flow
- [x] Client can raise a dispute (sets status, creates Dispute record with reason)
- [x] Email notifications via JobMailer (Sidekiq deliver_later) — see full list below

### Feedback window (48h)
- [x] Dual confirmation implemented (shop + client both mark complete)
- [x] 48h window: silence = confirmation — AutoConfirmJob (Sidekiq) scheduled on mark_complete, fires InvoicingService if client hasn't responded by deadline

---

## NOT DONE

### High priority

- [x] **Multi-shop request** — checkboxes on category page, max 5, sticky request bar with form, batch Job creation per shop, JobMailer.new_request per job (MultiShopRequestsController)
- [x] **Two-domain routing** — BookifyDomainConstraint / PopDomainConstraint; default_url_options per-request; Hosts::BOOKIFY + Hosts::POP constants; all mailer URLs use explicit host; DOMAIN_ROUTING=true enables in dev via lvh.me

### Medium priority

- [x] **BankID verification** — POP handles Criipto/BankID during onboarding; UI patched: BankID badge on member roster, disabled select + warning in quote form for unverified members, onboarding banner on freelancer dashboard
- [x] **Shop owner operates from payoutpartner.com** — shop_admin namespace is inside PopDomainConstraint; freelancer/booker namespaces too.

### Low priority / Proposed

- [х] **Bookify fee** — 100 kr flat per booking (proposed, "for team discussion", not committed). Would appear as a line on the invoice.
- [ ] **Reconciliation projects** — async snapshot reports, external_id matching. Parked for post-MVP.

---

## EXPLICITLY EXCLUDED

These are deliberate product decisions — do NOT implement:

- ENK/AS payouts — Bookify is lonn only, forever
- Card payments — bank transfer only
- B2C clients — organisasjonsnummer required
- Auto-assignment of jobs — manual only
- Reviews, ratings, escrow
- Mobile apps
- Hours logging (beyond work_hours on completion)
- Language and interpretation services (excluded from 60 skills)
