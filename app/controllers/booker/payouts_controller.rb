module Booker
  class PayoutsController < BaseController
    before_action :require_pop!, only: %i[sync_all]

    MAX_SYNC_BATCH = 20

    def index
      @payouts = Payout.joins(booking: :enrollment)
        .where(enrollments: { booker_id: current_user.id })
        .includes(booking: { enrollment: :freelancer })
        .order(created_at: :desc)
        .page(params[:page])
    end

    def show
      @payout = find_payout
      @booking = @payout.booking
      @enrollment = @booking.enrollment
    end

    def sync_all
      payouts = Payout.joins(booking: :enrollment)
        .where(enrollments: { booker_id: current_user.id })
        .where.not(pop_payout_id: nil)
        .limit(MAX_SYNC_BATCH)

      synced = 0
      failed = 0
      payouts.each do |payout|
        result = pop_client.get_payout(payout.pop_payout_id)
        if result.success?
          payout.update!(
            pop_status: result.data["status"],
            pop_response: result.data,
            synced_at: Time.current
          )
          synced += 1
        else
          failed += 1
        end
      end

      message = "Synced #{synced} payout(s) from POP."
      message += " #{failed} failed to sync." if failed > 0
      redirect_to booker_payouts_path, notice: message
    end

    private

    def find_payout
      Payout.joins(booking: :enrollment)
        .where(enrollments: { booker_id: current_user.id })
        .find(params[:id])
    end
  end
end
