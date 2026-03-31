require "rails_helper"

RSpec.describe "Callbacks", type: :request do
  describe "GET /callbacks/onboard" do
    let(:booker) { create(:user, :booker) }
    let(:enrollment) { create(:enrollment, booker: booker) }

    it "creates a freelancer user and activates the enrollment" do
      stub_pop_get_profile("wk_new", {
        "email" => "anna@example.com",
        "first_name" => "Anna",
        "last_name" => "Hansen"
      })

      get callbacks_onboard_path, params: { token: enrollment.invitation_token, worker_id: "wk_new", status: "approved" }

      enrollment.reload
      expect(enrollment.status).to eq("active")
      expect(enrollment.pop_worker_id).to eq("wk_new")
      expect(enrollment.pop_enrollment_id).to be_present
      expect(enrollment.freelancer).to be_present
      expect(enrollment.freelancer.email).to eq("anna@example.com")
      expect(enrollment.freelancer.freelancer?).to be true
    end

    it "links to existing freelancer user if email matches" do
      existing_freelancer = create(:user, :freelancer, email: "anna@example.com")

      stub_pop_get_profile("wk_existing", {
        "email" => "anna@example.com",
        "first_name" => "Anna",
        "last_name" => "Hansen"
      })

      get callbacks_onboard_path, params: { token: enrollment.invitation_token, worker_id: "wk_existing", status: "approved" }

      enrollment.reload
      expect(enrollment.freelancer).to eq(existing_freelancer)
    end

    it "rejects callback if existing user is a booker" do
      create(:user, :booker, email: "anna@example.com")

      stub_pop_get_profile("wk_booker", {
        "email" => "anna@example.com",
        "first_name" => "Anna",
        "last_name" => "Hansen"
      })

      get callbacks_onboard_path, params: { token: enrollment.invitation_token, worker_id: "wk_booker", status: "approved" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("booker")
    end

    it "redirects to invitation on POP failure" do
      stub_pop_unauthorized

      get callbacks_onboard_path, params: { token: enrollment.invitation_token, worker_id: "wk_fail", status: "approved" }

      enrollment.reload
      expect(enrollment.status).to eq("invited")
      expect(response).to redirect_to(invitation_path(token: enrollment.invitation_token))
    end

    it "rejects callback for an already-active enrollment" do
      active_enrollment = create(:enrollment, :active, booker: booker)

      get callbacks_onboard_path, params: { token: active_enrollment.invitation_token, worker_id: "wk_dup", status: "approved" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("already been used")
    end

    it "rejects callback with invalid token" do
      get callbacks_onboard_path, params: { token: "invalid", worker_id: "wk_fake", status: "approved" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Invalid")
    end

    it "rejects callback without approved status" do
      get callbacks_onboard_path, params: { token: enrollment.invitation_token, worker_id: "wk_new" }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("not completed")
    end

    it "handles abandoned_worker_id param" do
      stub_pop_get_profile("wk_new", {
        "email" => "anna@example.com",
        "first_name" => "Anna",
        "last_name" => "Hansen"
      })

      get callbacks_onboard_path, params: {
        token: enrollment.invitation_token,
        worker_id: "wk_new",
        status: "approved",
        abandoned_worker_id: "wk_old"
      }

      enrollment.reload
      expect(enrollment.status).to eq("active")
      expect(enrollment.pop_worker_id).to eq("wk_new")
    end
  end

  describe "GET /callbacks/manage" do
    let(:booker) { create(:user, :booker) }
    let(:freelancer) { create(:user, :freelancer) }
    let(:enrollment) { create(:enrollment, :active, booker: booker, freelancer: freelancer) }

    it "updates profile data when status is updated" do
      stub_pop_get_profile(enrollment.pop_worker_id)

      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(freelancer)
      get callbacks_manage_path, params: { worker_id: enrollment.pop_worker_id, status: "updated" }

      enrollment.reload
      expect(enrollment.pop_profile_data).to be_present
      expect(response).to redirect_to(freelancer_profile_path)
    end

    it "rejects callback without updated status" do
      get callbacks_manage_path, params: { worker_id: enrollment.pop_worker_id }

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("not completed")
    end
  end
end
