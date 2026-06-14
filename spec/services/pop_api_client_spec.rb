require "rails_helper"

RSpec.describe PopApiClient do
  subject(:client) { described_class.new }

  describe "#get_profile" do
    it "returns profile data on success" do
      stub_pop_get_profile("wk_123")

      result = client.get_profile("wk_123")

      expect(result.success?).to be true
      expect(result.data.dig("freelancer", "name")).to eq("Anna Hansen")
      expect(result.data["worker_id"]).to eq("wk_123")
      expect(result.status).to eq(200)
    end

    it "records the API call" do
      stub_pop_get_profile("wk_123")

      client.get_profile("wk_123")

      expect(client.api_calls.size).to eq(1)
      call = client.api_calls.first
      expect(call[:method]).to eq("GET")
      expect(call[:path]).to include("/api/v2/partner/profiles/wk_123")
      expect(call[:status]).to eq(200)
    end

    it "masks the bearer token showing only last 4 characters" do
      stub_pop_get_profile("wk_123")

      client.get_profile("wk_123")

      auth = client.api_calls.first[:headers]["Authorization"]
      expect(auth).to start_with("Bearer ***")
      expect(auth).not_to include("test-api")
    end
  end

  describe "#create_payout" do
    let(:work_lines) do
      [{ occupation_code: "2519", unit_price: 60_000, quantity: 3,
         duration: { start_date: "2026-06-10", end_date: "2026-06-10", duration_hours: 3 } }]
    end

    it "creates a payout on success" do
      stub_pop_create_payout

      result = client.create_payout(worker_id: "wk_123", idempotency_key: "idem-1", work_lines: work_lines)

      expect(result.success?).to be true
      expect(result.data["status"]).to eq("submitted")
      expect(result.status).to eq(201)
    end

    it "sends work_lines + a mandatory idempotency_key (øre, no NOK conversion)" do
      stub_pop_create_payout

      client.create_payout(worker_id: "wk_123", idempotency_key: "idem-1", work_lines: work_lines)

      expect(WebMock).to have_requested(:post, "#{PopApiHelpers::POP_BASE}/api/v2/partner/payouts").with { |req|
        body = JSON.parse(req.body)
        body["worker_id"] == "wk_123" &&
          body["idempotency_key"] == "idem-1" &&
          body.dig("work_lines", 0, "unit_price") == 60_000
      }
    end

    it "returns error on failure" do
      stub_pop_create_payout_failure

      result = client.create_payout(worker_id: "wk_bad", idempotency_key: "idem-2", work_lines: work_lines)

      expect(result.success?).to be false
      expect(result.error.code).to eq("validation_failed")
      expect(result.status).to eq(422)
    end

    it "captures multiple API calls" do
      stub_pop_get_profile("wk_123")
      stub_pop_create_payout

      client.get_profile("wk_123")
      client.create_payout(worker_id: "wk_123", idempotency_key: "idem-3", work_lines: work_lines)

      expect(client.api_calls.size).to eq(2)
      expect(client.api_calls.map { |c| c[:method] }).to eq(%w[GET POST])
    end
  end

  describe "#list_profiles" do
    it "returns profile data" do
      stub_pop_list_profiles

      result = client.list_profiles

      expect(result.success?).to be true
      expect(result.data["data"]).to be_an(Array)
    end
  end

  describe "#list_payouts" do
    it "returns payout data" do
      stub_pop_list_payouts

      result = client.list_payouts

      expect(result.success?).to be true
      expect(result.data["data"]).to be_an(Array)
    end
  end

  describe "#list_occupation_codes" do
    it "returns occupation codes" do
      stub_pop_list_occupation_codes

      result = client.list_occupation_codes

      expect(result.success?).to be true
      expect(result.data["data"].first["code"]).to eq("7223.14")
    end
  end

  describe "#start_enrollment" do
    it "POSTs worker_id + email + return_url and returns the handoff url" do
      stub_pop_enroll_session(url: "https://sandbox.app.payoutpartner.com/enroll?partner=acme&worker=wk_123")

      result = client.start_enrollment(
        worker_id: "wk_123",
        email: "freelancer@example.com",
        return_url: "https://bookify.app/callbacks/onboard"
      )

      expect(result.success?).to be true
      expect(result.data["url"]).to eq("https://sandbox.app.payoutpartner.com/enroll?partner=acme&worker=wk_123")

      expect(WebMock).to have_requested(:post, "#{PopApiHelpers::POP_BASE}/api/v2/partner/enroll_sessions")
        .with(body: hash_including(
          "worker_id" => "wk_123",
          "email" => "freelancer@example.com",
          "return_url" => "https://bookify.app/callbacks/onboard"
        ))
    end
  end

  describe "#start_payout_method_session" do
    it "POSTs to payout_method_sessions and returns the handoff url" do
      stub_pop_payout_method_session

      result = client.start_payout_method_session(
        worker_id: "wk_123", email: "freelancer@example.com",
        return_url: "https://bookify.app/callbacks/manage"
      )

      expect(result.success?).to be true
      expect(result.data["url"]).to be_present
    end
  end

  describe "error handling" do
    it "handles connection timeout" do
      stub_pop_api_down

      result = client.get_profile("wk_123")

      expect(result.success?).to be false
      expect(result.error.code).to eq("connection_error")
    end

    it "handles 401 unauthorized" do
      stub_pop_unauthorized

      result = client.get_profile("wk_123")

      expect(result.success?).to be false
      expect(result.error.code).to eq("unauthorized")
      expect(result.status).to eq(401)
    end

    it "handles non-JSON error responses gracefully" do
      stub_request(:get, "#{PopApiHelpers::POP_BASE}/api/v2/partner/profiles/wk_bad")
        .to_return(status: 502, body: "Bad Gateway", headers: { "Content-Type" => "text/html" })

      result = client.get_profile("wk_bad")

      expect(result.success?).to be false
      expect(result.error.message).to eq("Request failed")
      expect(result.status).to eq(502)
    end

    it "treats 3xx responses as errors" do
      stub_request(:get, "#{PopApiHelpers::POP_BASE}/api/v2/partner/profiles/wk_redir")
        .to_return(status: 302, body: "", headers: { "Location" => "https://other.com" })

      result = client.get_profile("wk_redir")

      expect(result.success?).to be false
    end
  end
end
