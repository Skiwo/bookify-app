require "rails_helper"

RSpec.describe "Booker::Bookings", type: :request do
  let(:booker) { create(:user, :booker, :pop_configured) }
  let(:enrollment) { create(:enrollment, :active, booker: booker) }

  before { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker) }

  describe "POST /booker/bookings/:id/pay" do
    let(:booking) { create(:booking, :completed, enrollment: enrollment) }

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
      draft_booking = create(:booking, enrollment: enrollment, status: :draft)

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

    it "sends trip_type for diet and receipt_url for expense sub-lines" do
      booking = create(:booking, :completed, enrollment: enrollment)
      booking.booking_lines.create!(line_type: :expense, booking_type: :time_based,
        description: "Taxi", rate_ore: 20_000, hours: 1, receipt_url: "https://example.com/r.pdf")
      booking.booking_lines.create!(line_type: :diet, booking_type: :time_based,
        description: "Per diem", rate_ore: 40_000, hours: 2, trip_type: "day_trip_over_12h")

      captured = nil
      stub_request(:post, "#{PopApiHelpers::POP_BASE}/api/v2/partner/payouts")
        .with { |req| captured = JSON.parse(req.body); true }
        .to_return(status: 201,
          body: { "id" => SecureRandom.uuid, "status" => "submitted", "amount" => 200_000 }.to_json,
          headers: { "Content-Type" => "application/json" })

      post pay_booker_booking_path(booking)

      subs = captured.fetch("work_lines").first.fetch("sub_lines")
      diet = subs.find { |s| s["line_type"] == "diet" }
      expense = subs.find { |s| s["line_type"] == "expense" }
      expect(diet["trip_type"]).to eq("day_trip_over_12h")
      expect(diet["unit_price"]).to eq(40_000)
      expect(expense["receipt_url"]).to eq("https://example.com/r.pdf")
    end

    it "refuses to pay a booking with no work line" do
      booking = create(:booking, :completed, enrollment: enrollment)
      booking.booking_lines.destroy_all
      booking.booking_lines.create!(line_type: :expense, booking_type: :time_based,
        description: "Taxi", rate_ore: 20_000, hours: 1, receipt_url: "https://example.com/r.pdf")

      post pay_booker_booking_path(booking)

      expect(response).to redirect_to(booker_booking_path(booking))
      expect(flash[:alert]).to include("work line")
      expect(booking.reload.payout).to be_nil
    end
  end

  describe "GET /booker/bookings/new" do
    it "renders the booking form (incl. diet trip_type + expense receipt fields)" do
      enrollment # the form only renders when the booker has an active freelancer
      stub_pop_list_occupation_codes

      get new_booker_booking_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Trip type (diet band)")
      expect(response.body).to include("day_trip_over_12h")
    end
  end

  describe "POST /booker/bookings/:id/complete" do
    it "marks a draft booking as completed" do
      booking = create(:booking, enrollment: enrollment, status: :draft)

      post complete_booker_booking_path(booking)

      expect(booking.reload.status).to eq("completed")
    end

    it "rejects completing a non-draft booking" do
      booking = create(:booking, :completed, enrollment: enrollment)

      post complete_booker_booking_path(booking)

      expect(response).to redirect_to(booker_booking_path(booking))
      expect(flash[:alert]).to include("draft")
    end
  end
end
