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

      assigned   = Job.joins(assigned_member: :enrollment).where(enrollments: { freelancer_id: current_user.id })
      solo_owned = Job.joins(:shop).where(shops: { owner_id: current_user.id, solo: true })
      all_jobs   = Job.where(id: assigned.select(:id)).or(Job.where(id: solo_owned.select(:id)))

      @status_filter = params[:status].presence
      @job_statuses  = all_jobs.distinct.pluck(:status)
                               .map { |s| s.is_a?(Integer) ? Job.statuses.key(s) : s.to_s }
                               .compact.sort
      filtered_jobs  = @status_filter ? all_jobs.where(status: @status_filter) : all_jobs

      @bookify_jobs  = filtered_jobs.includes(:shop, :client).order(created_at: :desc).page(params[:page]).per(10)
      @bookify_shops = all_jobs.includes(:shop).map(&:shop).uniq
      # Backfill bookify_pop_worker_id from enrollment or user if missing
      ShopMember
        .joins(:enrollment)
        .where(enrollments: { freelancer_id: current_user.id })
        .where.not(status: ShopMember.statuses[:inactive])
        .where(bookify_pop_worker_id: [nil, ""])
        .includes(enrollment: :freelancer)
        .each do |m|
          worker_id = m.enrollment&.pop_worker_id.presence ||
                      current_user.bookify_pop_worker_id.presence
          m.update_columns(bookify_pop_worker_id: worker_id) if worker_id.present?
        end

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
