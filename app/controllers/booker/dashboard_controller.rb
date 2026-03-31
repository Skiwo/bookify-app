module Booker
  class DashboardController < BaseController
    def show
      @enrollments = current_user.enrollments_as_booker
      @freelancer_count = @enrollments.active.count
      @completed_unpaid = Booking.where(enrollment: @enrollments).completed.left_joins(:payout).where(payouts: { id: nil }).count
      @total_payouts = Payout.joins(booking: :enrollment).where(enrollments: { booker_id: current_user.id }).count
      @recent_bookings = Booking.where(enrollment: @enrollments)
        .includes(:enrollment)
        .order(created_at: :desc)
        .limit(5)
      @recent_payouts = Payout.joins(booking: :enrollment)
        .where(enrollments: { booker_id: current_user.id })
        .includes(booking: { enrollment: :freelancer })
        .order(created_at: :desc)
        .limit(5)
    end

    def dismiss_welcome
      current_user.update!(welcome_dismissed: true)
      redirect_to booker_dashboard_path
    end
  end
end
