module Freelancer
  class DashboardController < BaseController
    def show
      @enrollments = current_user.enrollments_as_freelancer.active
      enrollment_ids = @enrollments.pluck(:id)
      @booker_count = @enrollments.count

      if enrollment_ids.any?
        stats = Booking.where(enrollment_id: enrollment_ids)
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

      @recent_bookings = Booking.where(enrollment_id: enrollment_ids)
        .includes(enrollment: :booker)
        .order(created_at: :desc)
        .limit(10)

      @recent_payouts = Payout.joins(:booking)
        .where(bookings: { enrollment_id: enrollment_ids })
        .includes(booking: { enrollment: :booker })
        .order(created_at: :desc)
        .limit(10)
    end
  end
end
