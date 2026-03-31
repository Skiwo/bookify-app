require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#invite" do
    let(:enrollment) { create(:enrollment) }
    let(:mail) { described_class.invite(enrollment) }

    it "sends to the enrollment email" do
      expect(mail.to).to eq([enrollment.email])
    end

    it "includes the booker name in the subject" do
      expect(mail.subject).to include(enrollment.booker.name)
    end

    it "includes the invitation link in the body" do
      expect(mail.body.encoded).to include(enrollment.invitation_token)
    end

    it "uses fallback when booker name is nil" do
      enrollment.booker.update_column(:name, nil)
      mail = described_class.invite(enrollment.reload)
      expect(mail.subject).to include("A Bookify user")
    end
  end
end
