require "rails_helper"

RSpec.describe Enrollment, type: :model do
  it { should belong_to(:booker).class_name("User") }
  it { should belong_to(:freelancer).class_name("User").optional }
  it { should have_many(:bookings) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:email) }
  it { should define_enum_for(:status).with_values(invited: 0, onboarding: 1, active: 2, removed: 3) }

  it "generates an invitation token on create" do
    enrollment = create(:enrollment)
    expect(enrollment.invitation_token).to be_present
  end

  it "normalizes email to lowercase" do
    enrollment = create(:enrollment, email: "Test@Example.COM")
    expect(enrollment.email).to eq("test@example.com")
  end

  describe "status transitions" do
    it "allows invited -> onboarding" do
      enrollment = create(:enrollment, status: :invited)
      enrollment.status = :onboarding
      expect(enrollment).to be_valid
    end

    it "prevents invited -> active (must go through onboarding)" do
      enrollment = create(:enrollment, status: :invited)
      enrollment.status = :active
      expect(enrollment).not_to be_valid
      expect(enrollment.errors[:status]).to be_present
    end

    it "allows onboarding -> active" do
      enrollment = create(:enrollment, status: :invited)
      enrollment.update!(status: :onboarding)
      enrollment.status = :active
      expect(enrollment).to be_valid
    end

    it "prevents active -> invited (no going backward)" do
      enrollment = create(:enrollment, :active)
      enrollment.status = :invited
      expect(enrollment).not_to be_valid
    end
  end

  describe "#pop_synced?" do
    it "returns true when active with pop_worker_id" do
      enrollment = create(:enrollment, :active)
      expect(enrollment.pop_synced?).to be true
    end

    it "returns false when invited" do
      enrollment = build(:enrollment, status: :invited)
      expect(enrollment.pop_synced?).to be false
    end
  end
end
