require "rails_helper"

RSpec.describe "Booker::Settings", type: :request do
  let(:booker) { create(:user, :booker) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker)
  end

  describe "GET /booker/settings" do
    it "renders the settings page" do
      get booker_settings_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /booker/settings" do
    it "saves sandbox credentials" do
      patch booker_settings_path, params: {
        user: {
          pop_sandbox_api_key: "pk_sandbox_test123",
          pop_sandbox_hmac_secret: "a" * 64,
          pop_sandbox_partner_id: SecureRandom.uuid
        }
      }

      expect(response).to redirect_to(booker_settings_path)
      expect(booker.reload.pop_configured?).to be true
    end

    it "switches to production environment" do
      patch booker_settings_path, params: {
        user: { pop_environment: "production" }
      }

      expect(response).to redirect_to(booker_settings_path)
      expect(booker.reload.pop_production?).to be true
    end
  end
end
