require "rails_helper"

RSpec.describe "Booker::Payouts", type: :request do
  let(:booker) { create(:user, :booker, :pop_configured) }
  let(:engagement) { create(:engagement, :active, booker: booker) }
  let!(:booking) { create(:booking, :paid, engagement: engagement) }

  before { allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(booker) }

  describe "POST /booker/payouts/sync_all" do
    it "syncs payout statuses from POP" do
      payout = booking.payout
      stub_pop_get_payout(payout.pop_payout_id, {
        "id" => payout.pop_payout_id,
        "status" => "paid",
        "amount" => 180_000
      })

      post sync_all_booker_payouts_path

      payout.reload
      expect(payout.pop_status).to eq("paid")
      expect(flash[:notice]).to include("Synced 1")
    end
  end
end
