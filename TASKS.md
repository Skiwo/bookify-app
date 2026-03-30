# Bookify + POP Core — Task List

Generated 2026-03-29 from a full codebase review of both `bookify-app` and `pop-core` (branch `partner-api-v2`).

---

## Bookify-App

### Bugs

- [ ] **CallbacksController spec asserts raise but controller rescues** — `callbacks_spec.rb` expects `RuntimeError` to propagate, but the controller rescues it and redirects. Fix the spec to assert on redirect/flash instead.
- [ ] **Request specs bypass `require_pop!`** — Booker specs (bookings, payouts, freelancers) use `create(:user, :booker)` without POP credentials. `User#pop_configured?` checks DB fields, not ENV. Specs likely redirect to settings instead of testing the happy path. Fix factory to include sandbox credentials.
- [ ] **`sync_all` silently swallows POP failures** — `PayoutsController#sync_all` shows "Synced N payout(s)" even when some `get_payout` calls fail. Show a count of failures too.
- [ ] **`BookingsController#create` accepts zero/negative rate** — `rate_nok <= 0` leaves `rate_ore` unset (or zero). Add model validation: `validates :rate_ore, numericality: { greater_than: 0 }`.

### Missing Features

- [ ] **Cancel booking** — `Booking` enum has `cancelled` status but no route, action, or UI to cancel a booking. Add `PATCH /booker/bookings/:id/cancel`.
- [ ] **Remove engagement** — `Engagement` enum has `removed` status but no UI to deactivate a freelancer relationship.
- [ ] **Enrollment list in UI** — `PopApiClient` has `list_enrollments` and `get_enrollment` methods but they're not wired into any controller/view. Add a POP Enrollments page under the booker namespace.
- [ ] **`pop_enrollment_id` column unused** — Exists in schema on `engagements` table but never read or written. Either use it (store POP enrollment ID during onboard callback) or remove it.

### Security

- [ ] **POP credentials stored in plaintext** — `pop_sandbox_api_key`, `pop_sandbox_hmac_secret`, etc. are stored unencrypted in the `users` table. Use Rails encrypted attributes or `attr_encrypted`.
- [ ] **Callback HMAC verification** — `callbacks#onboard` does not verify that the callback actually came from POP. It trusts the `worker_id` param and fetches the profile. Consider verifying a signed callback parameter.
- [ ] **Settings form leaks secrets in HTML** — Password fields in `booker/settings/show.html.haml` use `value: current_user.pop_sandbox_api_key`, putting the actual secret in the DOM source. Show masked values or omit the value attribute.

### Improvements

- [ ] **Surface POP error messages** — Booker pay/bundle/sync actions show generic "failed" alerts. Show `result.error.message` (sanitized) so the user understands what went wrong.
- [ ] **Occupation codes error in booking form** — `load_occupation_codes` sets `@occupation_codes_error` but confirm the view displays it. If POP is down, the booker should see a clear message.
- [ ] **Replace inline JS with Stimulus** — `_developer_notes.html.haml` and settings form use inline `onclick`/`onchange`. Create proper Stimulus controllers.
- [ ] **Add plain-text email template** — `invitation_mailer/invite.html.erb` has no `.text.erb` counterpart. Add one for email clients that prefer multipart.
- [ ] **README screenshots** — README says "Screenshots will be added after the UI is deployed". Add them.
- [ ] **`PopCredentialsMissing` not globally handled** — If credentials are deleted mid-session, any POP call raises `PopCredentialsMissing`. Add a `rescue_from` in `ApplicationController`.

### Tech Debt

- [ ] **Remove `_heroku` schema from `db/schema.rb`** — `create_schema "_heroku"` ties the dump to Heroku Postgres and breaks local `db:schema:load` on vanilla Postgres.
- [ ] **Test coverage gaps** — No specs for: `InvitationsController`, `PagesController`, `Booker::DashboardController`, `Booker::SettingsController`, all Freelancer controllers, `callbacks#manage`.
- [ ] **Request specs use `allow_any_instance_of`** — Bypasses real auth. Refactor to use Passwordless test helpers or sign-in helpers.
- [ ] **Content Security Policy commented out** — CSP initializer is disabled but layouts call `csp_meta_tag`. Either enable and configure CSP or remove the meta tag.
- [ ] **`filter_parameters` includes `:email`** — Overly broad; all parameters matching `email` are redacted from logs, hindering debugging. Be more specific.

---

## POP-Core (Partner API v2)

### Bugs

- [ ] **`InvoicesController#show` double render risk** — `find_invoice!` rescues `RecordNotFound`, calls `render_error`, but does not `return`. The action continues and may call `render_success` on nil.
- [ ] **`ManageController#edit_profile` missing return after redirect** — When `@profile` is nil, redirect fires but execution continues, risking double render.
- [ ] **Typo: "origanization"** in `CreatePartnerDecorator` error message. Should be "organization".
- [ ] **Typo: `partner_attibutes`** in `PartnersController`. Consistent internally but should be `partner_attributes`.

### Partner API Improvements

- [ ] **HTTP status codes too coarse** — `render_service_errors` always uses 422. Map service error codes to appropriate HTTP statuses (400 for bad params, 404 for not found, 409 for conflict).
- [ ] **`ParameterMissing` returns 500** — `params.require(:lines)` in `PayoutsController` raises `ActionController::ParameterMissing` which surfaces as 500. Add `rescue_from` to return 400 with structured JSON.
- [ ] **`ProfilesController` inconsistent response shape** — Returns a single object for one enrollment, an array for multiple. Always return `{ "profiles": [...] }` for predictable client parsing.
- [ ] **`BundlesController` returns 202 with no job tracking** — `call_later` provides no idempotency key or job ID. Partners can't check bundle status or retry safely.
- [ ] **Rack::Attack blocks legitimate "bot" user agents** — Blocklist matches `bot|crawler|spider|scraper` site-wide. Partner API clients with "bot" in their User-Agent get blocked. Scope to non-API paths or use allowlisting.

### Partner UI

- [ ] **API key shown only in flash** — `ApiKeysController` shows the new key in a flash message (easy to lose). Show it in a modal with copy button, then never show it again.
- [ ] **Docs page is empty** — `Partner::DocsController#index` renders an empty view. Link to the OpenAPI/Swagger docs, show base URL, auth examples.
- [x] **Partner signup success page** — `partners/create.html.haml` now shows Partner ID, API Key, and HMAC Secret in a clear table with save warning.
- [ ] **Partner portal pages crash** — Multiple pages in the partner portal (`manage.*`) are broken or unreadable. Full audit and fix needed.

### URL Structure Cleanup

- [ ] **Rename `partner_platform` routes for clarity** — Current naming is confusing: `app.*/partner_platform/manage` is for freelancers editing profiles, `manage.*` is the partner company portal. Consider: `app.*/freelancer/onboard`, `app.*/freelancer/profile` instead of overloading "manage". Clean URLs, update views, routes, redirects, and API docs in one focused session.

### Documentation

- [ ] **`V2_PARTNER_PLATFORM_API_PLAN.md` is outdated** — Still says "Design complete, ready for review and implementation" while most features are implemented. Update to reflect current state (implemented, deferred, changed).
- [ ] **Swagger file may be missing** — CI expects `swagger/v2/swagger.yaml`. Verify it exists on the branch and stays in sync via `rake rswag:specs:swaggerize`.
- [ ] **Security event logging incomplete** — Plan describes centralized logging of JWT failures, OTP failures, throttle hits. Only partially implemented (e.g., `SystemErrors::Create` in `ValidateIdentity`).

### Security

- [ ] **JWT decode reads `partner_id` unverified** — `PartnerPlatform::CreateSession` decodes unverified payload to get `partner_id`, then verifies. If `JWT.decode` without verification leaks timing info, this could be a concern. Consider always decoding with a noop algorithm check first.
- [ ] **JTI replay protection** — `PartnerSession.exists?(jti:)` blocks replay. Ensure old sessions are cleaned up (TTL or cron) to prevent table bloat.

---

## Bookify Marketing Website — Content Gaps (2026-03-30)

### Payout Flow Accuracy
- [ ] Explain that payout only happens **after the company pays the invoice** — not instantly
- [ ] Clarify that PayoutPartner reviews each invoice before accepting it
- [ ] Make clear the flow is: submit payout → PayoutPartner generates invoice → company pays invoice → freelancer gets paid

### Missing Feature Explanations
- [ ] **Bundle feature**: Companies can stage multiple payouts and submit them all at once as a single bundle, or send them individually
- [ ] **Idempotency Key**: The unique identifier between platforms for each payout — prevents duplicate submissions
- [ ] **External ID**: An identifier for a job — one job can have many payouts
- [ ] **Order Reference, Buyer Reference**: Important fields on payouts
- [ ] **Invoiced On, Due On**: Date fields that control invoice timing

### GitHub Repository
- [ ] Ruby badge in README says 3.2.0 — verify against actual `.ruby-version` and update
- [ ] Heroku deploy URL points to `payoutpartner/bookify-app` but repo is `skiwo/bookify-app` — one-click deploy button will 404
- [ ] Add prominent link to Partner API v2 docs (`sandbox.core.payoutpartner.com/partner/docs`) in README
- [ ] General README improvement — better structure, clearer setup instructions
- [ ] `tmp/` and `log/` — verify they're properly gitignored
- [ ] Consider whether TASKS.md should remain in a public repo — convert to public roadmap or move internal tasks elsewhere

---

## Cross-Cutting (Both Apps)

- [ ] **Local dev: bookify needs `dotenv-rails`** — Added in this session. Verify it loads `.env` correctly in development.
- [ ] **Local dev: `POP_BASE_URL` override** — Added in this session (`User#effective_pop_base_url`). Verify the full flow works end-to-end with localhost.
- [ ] **Procfile.dev missing in bookify** — `bin/dev` references `Procfile.dev` which doesn't exist. Create it or update `bin/dev` to use `Procfile`.
- [ ] **CORS for local dev** — Pop-core's CORS config should include `localhost:3000` for bookify. Verify the `.env` `CORS_ALLOWED_ORIGINS` value includes it.
- [ ] **End-to-end test** — No integration test covers the full flow: bookify invite -> POP onboard -> callback -> booking -> payout. Consider adding a smoke test script.
