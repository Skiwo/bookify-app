require "rails_helper"

RSpec.describe Booking, type: :model do
  it { should belong_to(:enrollment) }
  it { should have_one(:payout) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:rate_ore) }
  it { should validate_presence_of(:hours) }
  it { should validate_numericality_of(:rate_ore).only_integer.is_greater_than(0) }

  describe "#total_ore" do
    it "calculates rate * hours" do
      booking = build(:booking, rate_ore: 60_000, hours: 3)
      expect(booking.total_ore).to eq(180_000)
    end

    it "returns 0 when rate_ore is nil" do
      booking = build(:booking)
      booking.rate_ore = nil
      expect(booking.total_ore).to eq(0)
    end
  end

  describe "#rate_nok" do
    it "converts ore to NOK" do
      booking = build(:booking, rate_ore: 60_000)
      expect(booking.rate_nok).to eq(600.0)
    end

    it "returns nil when rate_ore is nil" do
      booking = build(:booking)
      booking.rate_ore = nil
      expect(booking.rate_nok).to be_nil
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
