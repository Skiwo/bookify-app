require "rails_helper"

RSpec.describe "Booker::Dashboard", type: :request do
  describe "GET /booker/dashboard" do
    it "renders for authenticated booker" do
      booker = create(:user, :booker)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker)

      get booker_dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects unauthenticated users to sign in" do
      get booker_dashboard_path
      expect(response).to redirect_to(users_sign_in_path)
    end

    it "rejects freelancer role" do
      freelancer = create(:user, :freelancer)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(freelancer)

      get booker_dashboard_path
      expect(response).to redirect_to(root_path)
    end
  end
end
