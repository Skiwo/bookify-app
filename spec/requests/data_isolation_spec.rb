require "rails_helper"

RSpec.describe "Data Isolation", type: :request do
  let(:booker_a) { create(:user, :booker, name: "Booker A") }
  let(:booker_b) { create(:user, :booker, name: "Booker B") }

  let!(:engagement_a) { create(:engagement, :active, booker: booker_a, name: "Freelancer for A") }
  let!(:engagement_b) { create(:engagement, :active, booker: booker_b, name: "Freelancer for B") }

  let!(:booking_a) { create(:booking, engagement: engagement_a, description: "Work for A") }
  let!(:booking_b) { create(:booking, engagement: engagement_b, description: "Work for B") }

  it "booker A cannot see booker B's freelancers" do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker_a)

    get booker_freelancers_path

    expect(response.body).to include("Freelancer for A")
    expect(response.body).not_to include("Freelancer for B")
  end

  it "booker A cannot see booker B's bookings" do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker_a)

    get booker_bookings_path

    expect(response.body).to include("Work for A")
    expect(response.body).not_to include("Work for B")
  end
end
