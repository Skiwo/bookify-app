require "rails_helper"

RSpec.describe "Freelancer::Profiles", type: :request do
  let(:booker) { create(:user, :booker, :pop_configured) }
  let(:freelancer) { create(:user, :freelancer) }
  let!(:enrollment) { create(:enrollment, :active, booker: booker, freelancer: freelancer) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(freelancer)
  end

  describe "GET /freelancer/profile" do
    it "renders the profile page" do
      stub_pop_get_profile(enrollment.pop_worker_id)

      get freelancer_profile_path
      expect(response).to have_http_status(:ok)
    end

    it "renders even when POP is down" do
      stub_pop_api_down

      get freelancer_profile_path
      expect(response).to have_http_status(:ok)
    end
  end
end
