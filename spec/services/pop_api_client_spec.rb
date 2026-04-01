require "rails_helper"

RSpec.describe PopApiClient do
  subject(:client) { described_class.new }

  describe "#get_profile" do
    it "returns profile data on success" do
      stub_pop_get_profile("wk_123")

      result = client.get_profile("wk_123")

      expect(result.success?).to be true
      expect(result.data.dig("freelancer", "first_name")).to eq("Anna")
      expect(result.data["partner_worker_id"]).to eq("wk_123")
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
    it "creates a payout on success" do
      stub_pop_create_payout

      result = client.create_payout(
        worker_id: "wk_123",
        lines: [{ description: "Work", rate: 600, quantity: 3 }]
      )

      expect(result.success?).to be true
      expect(result.data["status"]).to eq("submitted")
      expect(result.status).to eq(201)
    end

    it "returns error on failure" do
      stub_pop_create_payout_failure

      result = client.create_payout(
        worker_id: "wk_bad",
        lines: [{ description: "Work", rate: 600, quantity: 3 }]
      )

      expect(result.success?).to be false
      expect(result.error.code).to eq("validation_error")
      expect(result.status).to eq(422)
    end

    it "captures multiple API calls" do
      stub_pop_get_profile("wk_123")
      stub_pop_create_payout

      client.get_profile("wk_123")
      client.create_payout(worker_id: "wk_123", lines: [{ description: "Work", rate: 600, quantity: 1 }])

      expect(client.api_calls.size).to eq(2)
      expect(client.api_calls.map { |c| c[:method] }).to eq(%w[GET POST])
    end
  end

  describe "#list_enrollments" do
    it "returns enrollment data" do
      stub_pop_list_enrollments

      result = client.list_enrollments

      expect(result.success?).to be true
      expect(result.data["data"]).to be_an(Array)
    end
  end

  describe "#get_enrollment" do
    it "returns enrollment data" do
      stub_pop_get_enrollment("enr_123")

      result = client.get_enrollment("enr_123")

      expect(result.success?).to be true
      expect(result.data["id"]).to eq("enr_123")
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

  describe "#connect_url" do
    it "generates a signed JWT URL for the unified connect endpoint" do
      url = client.connect_url(
        worker_id: "wk_123",
        callback_url: "https://bookify.app/callbacks/connect"
      )

      expect(url).to start_with("https://sandbox.app.payoutpartner.com/freelancer/connect?token=")
      token = url.split("token=").last
      decoded = JWT.decode(token, PopApiHelpers::POP_ENV["POP_HMAC_SECRET"], true, algorithm: "HS256").first
      expect(decoded["partner_worker_id"]).to eq("wk_123")
      expect(decoded["partner_id"]).to eq(PopApiHelpers::POP_ENV["POP_PARTNER_ID"])
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
