require "rails_helper"

RSpec.describe "Freelancer::Dashboard", type: :request do
  describe "GET /freelancer/dashboard" do
    it "renders for authenticated freelancer" do
      freelancer = create(:user, :freelancer)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(freelancer)

      get freelancer_dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects unauthenticated users to sign in" do
      get freelancer_dashboard_path
      expect(response).to redirect_to(users_sign_in_path)
    end

    it "rejects booker role" do
      booker = create(:user, :booker)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker)

      get freelancer_dashboard_path
      expect(response).to redirect_to(root_path)
    end
  end
end
