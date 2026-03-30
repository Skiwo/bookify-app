require "rails_helper"

RSpec.describe "Callbacks", type: :request do
  describe "GET /callbacks/onboard" do
    let(:booker) { create(:user, :booker) }
    let(:engagement) { create(:engagement, booker: booker) }

    it "creates a freelancer user and activates the engagement" do
      stub_pop_get_profile("wk_new", {
        "email" => "anna@example.com",
        "first_name" => "Anna",
        "last_name" => "Hansen"
      })

      get callbacks_onboard_path, params: { token: engagement.invitation_token, worker_id: "wk_new" }

      engagement.reload
      expect(engagement.status).to eq("active")
      expect(engagement.pop_worker_id).to eq("wk_new")
      expect(engagement.freelancer).to be_present
      expect(engagement.freelancer.email).to eq("anna@example.com")
      expect(engagement.freelancer.freelancer?).to be true
    end

    it "links to existing freelancer user if email matches" do
      existing_freelancer = create(:user, :freelancer, email: "anna@example.com")

      stub_pop_get_profile("wk_existing", {
        "email" => "anna@example.com",
        "first_name" => "Anna",
        "last_name" => "Hansen"
      })

      get callbacks_onboard_path, params: { token: engagement.invitation_token, worker_id: "wk_existing" }

      engagement.reload
      expect(engagement.freelancer).to eq(existing_freelancer)
    end

    it "rejects callback if existing user is a booker" do
      create(:user, :booker, email: "anna@example.com")

      stub_pop_get_profile("wk_booker", {
        "email" => "anna@example.com",
        "first_name" => "Anna",
        "last_name" => "Hansen"
      })

      get callbacks_onboard_path, params: { token: engagement.invitation_token, worker_id: "wk_booker" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("booker")
    end

    it "redirects to invitation on POP failure" do
      stub_pop_unauthorized

      get callbacks_onboard_path, params: { token: engagement.invitation_token, worker_id: "wk_fail" }

      engagement.reload
      expect(engagement.status).to eq("invited")
      expect(response).to redirect_to(invitation_path(token: engagement.invitation_token))
    end

    it "rejects callback for an already-active engagement" do
      active_engagement = create(:engagement, :active, booker: booker)

      get callbacks_onboard_path, params: { token: active_engagement.invitation_token, worker_id: "wk_dup" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("already been used")
    end

    it "rejects callback with invalid token" do
      get callbacks_onboard_path, params: { token: "invalid", worker_id: "wk_fake" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Invalid")
    end
  end
end
