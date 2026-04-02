module Freelancer
  class BookingsController < BaseController
    def index
      enrollment_ids = current_user.enrollments_as_freelancer.pluck(:id)
      @bookings = Booking.where(enrollment_id: enrollment_ids)
        .includes(:booking_lines, enrollment: :booker)
        .order(created_at: :desc)
        .page(params[:page])
    end

    def show
      enrollment_ids = current_user.enrollments_as_freelancer.pluck(:id)
      @booking = Booking.where(enrollment_id: enrollment_ids)
        .includes(:booking_lines, :payout, enrollment: :booker)
        .find(params[:id])
    end
  end
end
