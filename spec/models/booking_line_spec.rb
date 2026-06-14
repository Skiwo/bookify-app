require "rails_helper"

RSpec.describe BookingLine, type: :model do
  it { should belong_to(:booking) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:rate_ore) }
  it { should validate_numericality_of(:rate_ore).only_integer.is_greater_than(0) }

  context "when time_based" do
    subject { build(:booking_line, booking_type: :time_based) }
    it { should validate_presence_of(:hours) }
    it { should validate_presence_of(:work_date) }
  end

  context "when project_based" do
    subject { build(:booking_line, :project_based) }
    it { should validate_presence_of(:total_hours) }
    it { should validate_presence_of(:work_start_date) }
    it { should validate_presence_of(:work_end_date) }
  end

  describe "#rate_nok=" do
    it "converts NOK to ore" do
      line = BookingLine.new
      line.rate_nok = "600"
      expect(line.rate_ore).to eq(60_000)
    end

    it "handles decimal rates" do
      line = BookingLine.new
      line.rate_nok = "599.50"
      expect(line.rate_ore).to eq(59_950)
    end
  end

  describe "#rate_nok" do
    it "converts ore to NOK" do
      line = build(:booking_line, rate_ore: 60_000)
      expect(line.rate_nok).to eq(600.0)
    end
  end

  describe "#effective_hours" do
    it "returns hours for time-based" do
      line = build(:booking_line, hours: 3.0)
      expect(line.effective_hours).to eq(3.0)
    end

    it "returns total_hours for project-based" do
      line = build(:booking_line, :project_based, total_hours: 40.0)
      expect(line.effective_hours).to eq(40.0)
    end
  end

  describe "#total_ore" do
    it "calculates rate * hours" do
      line = build(:booking_line, rate_ore: 60_000, hours: 3)
      expect(line.total_ore).to eq(180_000)
    end
  end

  describe "dependent sub-line validations (POP contract)" do
    # belongs_to :booking is required, so attach one to isolate the line's own rules.
    let(:booking) { build(:booking) }

    it "requires a receipt_url for expense lines" do
      line = build(:booking_line, booking: booking, line_type: :expense, receipt_url: nil)
      expect(line).not_to be_valid
      expect(line.errors[:receipt_url]).to be_present
    end

    it "accepts an expense line with a receipt_url" do
      line = build(:booking_line, booking: booking, line_type: :expense, receipt_url: "https://example.com/r.pdf")
      expect(line).to be_valid
    end

    it "requires a valid trip_type for diet lines" do
      expect(build(:booking_line, booking: booking, line_type: :diet, trip_type: nil)).not_to be_valid
      line = build(:booking_line, booking: booking, line_type: :diet, trip_type: "nope")
      expect(line).not_to be_valid
      expect(line.errors[:trip_type]).to be_present
    end

    it "accepts a diet line with a valid trip_type" do
      expect(build(:booking_line, booking: booking, line_type: :diet, trip_type: "day_trip_over_12h")).to be_valid
    end

    it "does not require receipt_url or trip_type for benefit lines" do
      expect(build(:booking_line, booking: booking, line_type: :benefit)).to be_valid
    end
  end
end
