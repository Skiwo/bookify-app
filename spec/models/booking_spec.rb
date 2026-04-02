require "rails_helper"

RSpec.describe Booking, type: :model do
  it { should belong_to(:enrollment) }
  it { should have_many(:booking_lines).dependent(:destroy) }
  it { should have_one(:payout) }
  it { should accept_nested_attributes_for(:booking_lines).allow_destroy(true) }

  describe "#total_ore" do
    it "aggregates from booking lines" do
      booking = build(:booking)
      booking.booking_lines = [
        build(:booking_line, rate_ore: 60_000, hours: 3),
        build(:booking_line, rate_ore: 40_000, hours: 2)
      ]
      expect(booking.total_ore).to eq(260_000)
    end
  end

  describe "#summary" do
    it "uses description when present" do
      booking = build(:booking, description: "March work")
      expect(booking.summary).to eq("March work")
    end

    it "falls back to first line description" do
      booking = build(:booking, description: nil)
      expect(booking.summary).to eq(booking.booking_lines.first.description)
    end
  end

  describe "#has_payout?" do
    it "returns true when payout exists" do
      booking = create(:booking, :paid)
      expect(booking.has_payout?).to be true
    end

    it "returns false when no payout" do
      booking = create(:booking)
      expect(booking.has_payout?).to be false
    end
  end
end
