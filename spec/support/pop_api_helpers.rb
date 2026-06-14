module PopApiHelpers
  POP_BASE = "https://sandbox.api.payoutpartner.com"

  POP_ENV = {
    "POP_API_KEY" => "pk_sandbox_test",
    "POP_BASE_URL" => POP_BASE,
    "POP_APP_URL" => "https://sandbox.app.payoutpartner.com"
  }.freeze

  # GET /profiles/:worker_id — POP's masked ProfileBlueprint (API v2).
  # Pass a flat hash like { "name" => "x", "email" => "y" } and it is nested
  # under "freelancer" automatically.
  def stub_pop_get_profile(worker_id, response_body = nil)
    if response_body && !response_body.key?("freelancer")
      response_body = profile_body(worker_id, freelancer: default_freelancer.merge(response_body))
    end
    body = response_body || profile_body(worker_id)
    stub_request(:get, "#{POP_BASE}/api/v2/partner/profiles/#{worker_id}")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def default_freelancer
    {
      "name" => "Anna Hansen",
      "email" => "freelancer@example.com",
      "freelance_type" => "individual",
      "organization_number" => nil,
      "personal_number" => "250482*****", # masked
      "address" => { "line1" => "Testgata 1", "postal_code" => "0150", "city" => "Oslo", "country" => "NO" }
    }
  end

  def profile_body(worker_id, freelancer: default_freelancer)
    {
      "worker_id" => worker_id,
      "status" => "approved",
      "payout_preference" => "salary",
      "freelancer" => freelancer,
      "payout_method" => {
        "bank_account_number" => "****8903", # masked
        "currency" => "NOK",
        "tax_rate" => "22%",
        "tax_card_valid" => true,
        "frikort_amount" => 0
      },
      "created_at" => Time.current.iso8601,
      "updated_at" => Time.current.iso8601
    }
  end

  def stub_pop_create_payout(response_body = nil)
    body = response_body || {
      "id" => SecureRandom.uuid,
      "status" => "submitted",
      "worker_id" => "wk_123",
      "invoice_number" => nil,
      "amount" => 180_000,
      "vat" => 45_000,
      "total" => 225_000,
      "currency" => "NOK",
      "paid_out_at" => nil
    }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/payouts")
      .to_return(status: 201, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_create_payout_failure(code: "validation_failed", message: "Invalid worker")
    body = { "error" => { "code" => code, "message" => message } }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/payouts")
      .to_return(status: 422, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_get_payout(payout_id, response_body = nil)
    body = response_body || {
      "id" => payout_id, "status" => "approved", "invoice_number" => "INV-2026-001",
      "amount" => 180_000, "total" => 225_000, "currency" => "NOK", "paid_out_at" => nil
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/payouts/#{payout_id}")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_list_profiles(response_body = nil)
    body = response_body || {
      "data" => [profile_body("wk_123")],
      "pagination" => { "page" => 1, "total_count" => 1 }
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/profiles")
      .with(query: hash_including({}))
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_list_payouts(response_body = nil)
    body = response_body || {
      "data" => [{ "id" => SecureRandom.uuid, "status" => "submitted" }],
      "pagination" => { "page" => 1, "total_count" => 1 }
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/payouts")
      .with(query: hash_including({}))
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_list_occupation_codes
    body = {
      "data" => [
        { "code" => "7223.14", "name" => "Graphic design", "vat_exempt" => false },
        { "code" => "5321.11", "name" => "Translation", "vat_exempt" => false }
      ],
      "pagination" => { "page" => 1, "total_count" => 2 }
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/occupation_codes")
      .with(query: hash_including({}))
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_api_down
    stub_request(:any, /#{Regexp.escape(POP_BASE)}/).to_timeout
  end

  def stub_pop_unauthorized
    body = { "error" => { "code" => "unauthorized", "message" => "Invalid API key" } }
    stub_request(:any, /#{Regexp.escape(POP_BASE)}/)
      .to_return(status: 401, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  # POST /enroll_sessions → POP emails the freelancer a 6-digit code and returns
  # a non-secret co-branded handoff URL on app.*.
  def stub_pop_enroll_session(url: "https://sandbox.app.payoutpartner.com/enroll?partner=acme&worker=wk_123")
    body = { "id" => "es_#{SecureRandom.hex(6)}", "url" => url, "expires_at" => 30.minutes.from_now.iso8601 }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/enroll_sessions")
      .to_return(status: 201, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  # POST /payout_method_sessions → same OTP handoff, lands on the preference portal.
  def stub_pop_payout_method_session(url: "https://sandbox.app.payoutpartner.com/enroll?partner=acme&worker=wk_123&p=manage")
    body = { "id" => "pms_#{SecureRandom.hex(6)}", "url" => url, "expires_at" => 30.minutes.from_now.iso8601 }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/payout_method_sessions")
      .to_return(status: 201, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end
end

RSpec.configure do |config|
  config.include PopApiHelpers

  config.around(:each) do |example|
    ClimateControl.modify(PopApiHelpers::POP_ENV) do
      example.run
    end
  end
end
