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

      assigned = Job.joins(assigned_member: :enrollment)
        .where(enrollments: { freelancer_id: current_user.id })
      solo_owned = Job.joins(:shop).where(shops: { owner_id: current_user.id, solo: true })
      @bookify_jobs = Job.where(id: assigned.select(:id)).or(Job.where(id: solo_owned.select(:id)))
        .includes(:shop, :client)
        .order(created_at: :desc)

      @bookify_shops = @bookify_jobs.map(&:shop).uniq
      @unverified_bookify_members = ShopMember
        .joins(:enrollment)
        .where(enrollments: { freelancer_id: current_user.id })
        .where.not(status: ShopMember.statuses[:inactive])
        .where(bookify_pop_worker_id: [nil, ""])
        .includes(:shop)

      @bookify_total_earned = Payout.joins(:booking)
        .where(bookings: { enrollment_id: enrollment_ids })
        .joins("INNER JOIN jobs ON jobs.booking_id = bookings.id")
        .sum("payouts.amount_ore")
    end
  end
end
