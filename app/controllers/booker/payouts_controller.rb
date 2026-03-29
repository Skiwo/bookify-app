module Booker
  class PayoutsController < BaseController
    before_action :require_pop!, only: %i[bundle sync_all]

    MAX_SYNC_BATCH = 20

    def index
      @payouts = Payout.joins(booking: :engagement)
        .where(engagements: { booker_id: current_user.id })
        .includes(booking: { engagement: :freelancer })
        .order(created_at: :desc)
        .page(params[:page])
    end

    def show
      @payout = find_payout
      @booking = @payout.booking
      @engagement = @booking.engagement
    end

    def bundle
      result = pop_client.create_bundle
      if result.success?
        redirect_to booker_payouts_path, notice: "Bundle request submitted to POP."
      else
        redirect_to booker_payouts_path, alert: "Bundle failed. Please try again."
      end
    end

    def sync_all
      payouts = Payout.joins(booking: :engagement)
        .where(engagements: { booker_id: current_user.id })
        .where.not(pop_payout_id: nil)
        .limit(MAX_SYNC_BATCH)

      synced = 0
      payouts.each do |payout|
        result = pop_client.get_payout(payout.pop_payout_id)
        if result.success?
          payout.update!(
            pop_status: result.data["status"],
            pop_response: result.data,
            synced_at: Time.current
          )
          synced += 1
        end
      end

      redirect_to booker_payouts_path, notice: "Synced #{synced} payout(s) from POP."
    end

    private

    def find_payout
      Payout.joins(booking: :engagement)
        .where(engagements: { booker_id: current_user.id })
        .find(params[:id])
    end
  end
end
