module Freelancer
  class BookingsController < BaseController
    def index
      engagement_ids = current_user.engagements_as_freelancer.pluck(:id)
      @bookings = Booking.where(engagement_id: engagement_ids)
        .includes(engagement: :booker)
        .order(created_at: :desc)
        .page(params[:page])
    end

    def show
      engagement_ids = current_user.engagements_as_freelancer.pluck(:id)
      @booking = Booking.where(engagement_id: engagement_ids)
        .includes(:payout, engagement: :booker)
        .find(params[:id])
    end
  end
end
