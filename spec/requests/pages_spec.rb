require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders landing page for unauthenticated users" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "redirects bookers to dashboard" do
      booker = create(:user, :booker)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker)

      get root_path
      expect(response).to redirect_to(booker_dashboard_path)
    end

    it "redirects freelancers to dashboard" do
      freelancer = create(:user, :freelancer)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(freelancer)

      get root_path
      expect(response).to redirect_to(freelancer_dashboard_path)
    end
  end

  describe "GET /about" do
    it "renders" do
      get about_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /privacy" do
    it "renders" do
      get privacy_path
      expect(response).to have_http_status(:ok)
    end
  end
end
