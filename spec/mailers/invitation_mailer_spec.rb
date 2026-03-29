require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#invite" do
    let(:engagement) { create(:engagement) }
    let(:mail) { described_class.invite(engagement) }

    it "sends to the engagement email" do
      expect(mail.to).to eq([engagement.email])
    end

    it "includes the booker name in the subject" do
      expect(mail.subject).to include(engagement.booker.name)
    end

    it "includes the invitation link in the body" do
      expect(mail.body.encoded).to include(engagement.invitation_token)
    end

    it "uses fallback when booker name is nil" do
      engagement.booker.update_column(:name, nil)
      mail = described_class.invite(engagement.reload)
      expect(mail.subject).to include("A Bookify user")
    end
  end
end
