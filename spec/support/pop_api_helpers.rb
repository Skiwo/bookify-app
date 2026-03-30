module PopApiHelpers
  POP_BASE = "https://sandbox.core.payoutpartner.com"

  POP_ENV = {
    "POP_API_KEY" => "test-api-key",
    "POP_HMAC_SECRET" => "test-hmac-secret",
    "POP_PARTNER_ID" => "test-partner-id",
    "POP_BASE_URL" => POP_BASE
  }.freeze

  def stub_pop_get_profile(worker_id, response_body = nil)
    body = response_body || {
      "id" => worker_id,
      "email" => "freelancer@example.com",
      "first_name" => "Anna",
      "last_name" => "Hansen",
      "status" => "active"
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/profiles/#{worker_id}")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_create_payout(response_body = nil)
    body = response_body || {
      "id" => SecureRandom.uuid,
      "status" => "submitted",
      "invoice_number" => "INV-2026-001",
      "amount" => 180_000
    }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/payouts")
      .to_return(status: 201, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_create_payout_failure(code: "validation_error", message: "Invalid worker")
    body = { "error" => { "code" => code, "message" => message } }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/payouts")
      .to_return(status: 422, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_get_payout(payout_id, response_body = nil)
    body = response_body || {
      "id" => payout_id,
      "status" => "approved",
      "invoice_number" => "INV-2026-001",
      "amount" => 180_000
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/payouts/#{payout_id}")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_list_enrollments(response_body = nil)
    body = response_body || {
      "data" => [{ "id" => SecureRandom.uuid, "status" => "approved" }],
      "pagination" => { "page" => 1, "total_count" => 1 }
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/enrollments")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_get_enrollment(enrollment_id, response_body = nil)
    body = response_body || { "id" => enrollment_id, "status" => "approved" }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/enrollments/#{enrollment_id}")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_list_payouts(response_body = nil)
    body = response_body || {
      "data" => [{ "id" => SecureRandom.uuid, "status" => "submitted" }],
      "pagination" => { "page" => 1, "total_count" => 1 }
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/payouts")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_list_occupation_codes
    body = {
      "data" => [
        { "code" => "7223.14", "name" => "Graphic design" },
        { "code" => "5321.11", "name" => "Translation" }
      ],
      "pagination" => { "page" => 1, "total_count" => 2 }
    }
    stub_request(:get, "#{POP_BASE}/api/v2/partner/occupation_codes")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_deactivate_enrollment(enrollment_id)
    body = { "id" => enrollment_id, "status" => "deactivated", "approved" => false }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/enrollments/#{enrollment_id}/deactivate")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_pop_reactivate_enrollment(enrollment_id)
    body = { "id" => enrollment_id, "status" => "approved", "approved" => true }
    stub_request(:post, "#{POP_BASE}/api/v2/partner/enrollments/#{enrollment_id}/reactivate")
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
end

RSpec.configure do |config|
  config.include PopApiHelpers

  config.around(:each) do |example|
    ClimateControl.modify(PopApiHelpers::POP_ENV) do
      example.run
    end
  end
end
