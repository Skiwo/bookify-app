require "rails_helper"

RSpec.describe Payout, type: :model do
  subject { create(:payout) }

  it { should belong_to(:booking) }
  it { should validate_uniqueness_of(:booking_id).ignoring_case_sensitivity }

  describe "#amount_nok" do
    it "converts ore to NOK" do
      payout = build(:payout, amount_ore: 180_000)
      expect(payout.amount_nok).to eq(1800.0)
    end

    it "returns nil when amount_ore is nil" do
      payout = build(:payout, amount_ore: nil)
      expect(payout.amount_nok).to be_nil
    end
  end

  describe "#synced?" do
    it "returns true when synced_at is set" do
      payout = build(:payout, synced_at: Time.current)
      expect(payout.synced?).to be true
    end

    it "returns false when synced_at is nil" do
      payout = build(:payout, synced_at: nil)
      expect(payout.synced?).to be false
    end
  end
end
