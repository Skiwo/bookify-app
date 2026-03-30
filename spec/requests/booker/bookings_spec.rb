require "rails_helper"

RSpec.describe "Booker::Bookings", type: :request do
  let(:booker) { create(:user, :booker, :pop_configured) }
  let(:engagement) { create(:engagement, :active, booker: booker) }

  before { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker) }

  describe "POST /booker/bookings/:id/pay" do
    let(:booking) { create(:booking, :completed, engagement: engagement) }

    it "creates a payout via POP API" do
      stub_pop_create_payout

      post pay_booker_booking_path(booking)

      booking.reload
      expect(booking.status).to eq("paid")
      expect(booking.payout).to be_present
      expect(booking.payout.pop_status).to eq("submitted")
    end

    it "shows error when POP rejects the payout" do
      stub_pop_create_payout_failure(message: "Worker not approved")

      post pay_booker_booking_path(booking)

      expect(response).to redirect_to(booker_booking_path(booking))
      expect(flash[:alert]).to include("Payout failed")
      expect(booking.reload.payout).to be_nil
    end

    it "rejects payment for draft bookings" do
      draft_booking = create(:booking, engagement: engagement, status: :draft)

      post pay_booker_booking_path(draft_booking)

      expect(response).to redirect_to(booker_booking_path(draft_booking))
      expect(flash[:alert]).to include("completed")
    end

    it "rejects duplicate payment" do
      stub_pop_create_payout
      post pay_booker_booking_path(booking)

      post pay_booker_booking_path(booking)

      expect(response).to redirect_to(booker_booking_path(booking))
      expect(flash[:alert]).to include("already been paid")
    end
  end

  describe "POST /booker/bookings/:id/complete" do
    it "marks a draft booking as completed" do
      booking = create(:booking, engagement: engagement, status: :draft)

      post complete_booker_booking_path(booking)

      expect(booking.reload.status).to eq("completed")
    end

    it "rejects completing a non-draft booking" do
      booking = create(:booking, :completed, engagement: engagement)

      post complete_booker_booking_path(booking)

      expect(response).to redirect_to(booker_booking_path(booking))
      expect(flash[:alert]).to include("draft")
    end
  end
end
