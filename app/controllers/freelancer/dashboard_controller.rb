module Freelancer
  class DashboardController < BaseController
    def show
      @engagements = current_user.engagements_as_freelancer.active
      engagement_ids = @engagements.pluck(:id)
      @booker_count = @engagements.count

      if engagement_ids.any?
        stats = Booking.where(engagement_id: engagement_ids)
          .left_joins(:payout)
          .pick(
            Arel.sql("COUNT(*)"),
            Arel.sql("COALESCE(SUM(payouts.amount_ore), 0)")
          )
        @total_bookings = stats[0] || 0
        @total_paid = stats[1] || 0
      else
        @total_bookings = 0
        @total_paid = 0
      end

      @recent_bookings = Booking.where(engagement_id: engagement_ids)
        .includes(engagement: :booker)
        .order(created_at: :desc)
        .limit(10)

      @recent_payouts = Payout.joins(:booking)
        .where(bookings: { engagement_id: engagement_ids })
        .includes(booking: { engagement: :booker })
        .order(created_at: :desc)
        .limit(10)
    end
  end
end
