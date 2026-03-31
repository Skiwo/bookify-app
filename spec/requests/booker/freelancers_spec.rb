require "rails_helper"

RSpec.describe "Booker::Freelancers", type: :request do
  let(:booker) { create(:user, :booker, :pop_configured) }

  before { post "/users/sign_in", params: { passwordless: { email: booker.email } } rescue nil; allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker) }

  describe "POST /booker/freelancers" do
    it "creates an enrollment and sends an invitation" do
      expect {
        post booker_freelancers_path, params: { enrollment: { name: "Anna", email: "anna@test.com" } }
      }.to change(Enrollment, :count).by(1)

      enrollment = Enrollment.last
      expect(enrollment.name).to eq("Anna")
      expect(enrollment.email).to eq("anna@test.com")
      expect(enrollment.booker).to eq(booker)
      expect(enrollment.invited?).to be true
    end
  end

  describe "GET /booker/freelancers" do
    it "only shows current booker's enrollments" do
      own = create(:enrollment, booker: booker, name: "My Freelancer")
      other = create(:enrollment, name: "Other Freelancer")

      get booker_freelancers_path

      expect(response.body).to include(own.name)
      expect(response.body).not_to include(other.name)
    end
  end
end
