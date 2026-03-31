require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:booker) { create(:user, :booker, :pop_configured) }
  let(:enrollment) { create(:enrollment, booker: booker) }

  describe "GET /invitations/:token" do
    it "shows the invitation page" do
      get invitation_path(token: enrollment.invitation_token)
      expect(response).to have_http_status(:ok)
    end

    it "redirects for invalid token" do
      get invitation_path(token: "nonexistent")
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /invitations/:token/accept" do
    it "redirects to POP connect URL" do
      post accept_invitation_path(token: enrollment.invitation_token)

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("payoutpartner.com/freelancer/connect")
      expect(enrollment.reload.status).to eq("onboarding")
    end

    it "rejects if booker has no POP credentials" do
      unconfigured_booker = create(:user, :booker)
      unconfigured_enrollment = create(:enrollment, booker: unconfigured_booker)

      post accept_invitation_path(token: unconfigured_enrollment.invitation_token)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("hasn't connected")
    end

    it "rejects already-accepted enrollment" do
      active_enrollment = create(:enrollment, :active, booker: booker)

      post accept_invitation_path(token: active_enrollment.invitation_token)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("already been accepted")
    end
  end
end
