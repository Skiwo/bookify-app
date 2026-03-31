require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user, :booker) }

  it { should validate_presence_of(:email) }
  it { should validate_uniqueness_of(:email).case_insensitive }
  it { should validate_presence_of(:role) }
  it { should define_enum_for(:role).with_values(booker: 0, freelancer: 1) }

  it "normalizes email to lowercase" do
    user = create(:user, :booker, email: "Test@Example.COM")
    expect(user.email).to eq("test@example.com")
  end

  it "rejects invalid email formats" do
    user = build(:user, :booker, email: "not-an-email")
    expect(user).not_to be_valid
    expect(user.errors[:email]).to be_present
  end
end
