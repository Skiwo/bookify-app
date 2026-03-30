require "rails_helper"

RSpec.describe Engagement, type: :model do
  it { should belong_to(:booker).class_name("User") }
  it { should belong_to(:freelancer).class_name("User").optional }
  it { should have_many(:bookings) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:email) }
  it { should define_enum_for(:status).with_values(invited: 0, onboarding: 1, active: 2, removed: 3) }

  it "generates an invitation token on create" do
    engagement = create(:engagement)
    expect(engagement.invitation_token).to be_present
  end

  it "normalizes email to lowercase" do
    engagement = create(:engagement, email: "Test@Example.COM")
    expect(engagement.email).to eq("test@example.com")
  end

  describe "status transitions" do
    it "allows invited -> onboarding" do
      engagement = create(:engagement, status: :invited)
      engagement.status = :onboarding
      expect(engagement).to be_valid
    end

    it "prevents invited -> active (must go through onboarding)" do
      engagement = create(:engagement, status: :invited)
      engagement.status = :active
      expect(engagement).not_to be_valid
      expect(engagement.errors[:status]).to be_present
    end

    it "allows onboarding -> active" do
      engagement = create(:engagement, status: :invited)
      engagement.update!(status: :onboarding)
      engagement.status = :active
      expect(engagement).to be_valid
    end

    it "prevents active -> invited (no going backward)" do
      engagement = create(:engagement, :active)
      engagement.status = :invited
      expect(engagement).not_to be_valid
    end
  end

  describe "#pop_synced?" do
    it "returns true when active with pop_worker_id" do
      engagement = create(:engagement, :active)
      expect(engagement.pop_synced?).to be true
    end

    it "returns false when invited" do
      engagement = build(:engagement, status: :invited)
      expect(engagement.pop_synced?).to be false
    end
  end
end
