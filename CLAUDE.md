# CLAUDE.md — Bookify App

Bookify is an open-source reference application built on the Payout Partner API v2. It demonstrates freelancer onboarding, booking management, payout creation, and invoice bundling.

This is a **public repository** — do not add credentials, secrets, or internal-only information here.

## Stack

- Ruby 3.2.x, Rails 8.0
- PostgreSQL
- HAML templates, Importmap, Turbo, Stimulus
- Passwordless authentication (magic link)
- Deployed on Heroku

## Run Locally

### Prerequisites

- Ruby 3.2.x (3.2.0+ works; Gemfile uses `~> 3.2.0`)
- PostgreSQL running and accessible
- Bundler

### Setup

```bash
# Install gems (use local path if system Ruby lacks write permissions)
bundle config set --local path vendor/bundle
bundle install

# Copy and edit environment variables
cp .env.sample .env
# Edit .env — set DATABASE_URL and SECRET_KEY_BASE at minimum

# Create and migrate the database
bundle exec rails db:create db:migrate db:seed

# Start the server
bundle exec rails s -p 3000
# Visit http://localhost:3000
```

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Yes | Generate with `rails secret` |
| `POP_BASE_URL` | No | POP API base URL (default: sandbox) |
| `POP_API_KEY` | No | Per-booker in Settings, or set globally here |
| `POP_HMAC_SECRET` | No | Per-booker in Settings, or set globally here |
| `POP_PARTNER_ID` | No | Per-booker in Settings, or set globally here |

Emails open in the browser via `letter_opener` in development — no SMTP needed locally.

## Commands

```bash
bundle exec rails s              # Start dev server (port 3000)
bundle exec rspec                # Run all specs
bundle exec rspec spec/services/ # PopApiClient specs only
bundle exec rspec spec/requests/ # Request specs only
```

## Architecture

- **Users** are either bookers or freelancers (enum role)
- **Enrollments** link a booker to a freelancer, track invitation status and POP worker ID (maps to POP's enrollment concept)
- **Bookings** represent units of work with rate (stored in ore) and hours
- **Payouts** are payments processed through POP, storing the full API response
- All monetary values are in ore (1/100 NOK). `rate_ore = 60000` means 600.00 NOK/hr

### Key Files

| File | Purpose |
|------|---------|
| `app/services/pop_api_client.rb` | Wraps all POP API v2 endpoints |
| `app/controllers/callbacks_controller.rb` | POP onboard/manage redirects |
| `app/controllers/booker/` | Booker dashboard, freelancers, bookings, payouts |
| `app/controllers/freelancer/` | Freelancer dashboard + profile |
| `app/views/shared/_developer_notes.html.haml` | Slide-out API call panel |

## Tests

Tests use WebMock to stub POP API calls — no network required.
