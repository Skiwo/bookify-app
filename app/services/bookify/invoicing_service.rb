module Bookify
  class InvoicingService
    Result = Struct.new(:success, :error, keyword_init: true) do
      def success? = success
    end

    def initialize(job)
      @job = job
    end

    def call
      validate!

      booking = build_booking_in_db
      result = submit_to_pop(booking)

      if result.success?
        record_payout(booking, result.data)
        Result.new(success: true)
      else
        booking.destroy
        @job.update!(status: :accepted)
        Result.new(success: false, error: result.error)
      end
    end

    private

    def validate!
      raise ArgumentError, "Job must be pending_confirmation" unless @job.pending_confirmation?
      raise ArgumentError, "No assigned member" unless @job.assigned_member
      raise ArgumentError, "No work amount" unless @job.work_amount_ore.to_i > 0
      raise ArgumentError, "Shop has no POP worker ID" unless @job.shop.pop_worker_id.present?
      raise ArgumentError, "Member has no POP worker ID" unless member_enrollment.pop_worker_id.present?
    end

    def member_enrollment
      @member_enrollment ||= @job.assigned_member.enrollment
    end

    def build_booking_in_db
      ActiveRecord::Base.transaction do
        booking = Booking.create!(
          enrollment: member_enrollment,
          description: @job.title,
          invoiced_on: Date.current,
          due_on: Date.current + 14.days,
          status: :completed
        )

        booking.booking_lines.create!(
          description: @job.title,
          line_type: :work,
          booking_type: :project_based,
          rate_ore: @job.work_amount_ore,
          total_hours: 1,
          work_start_date: Date.current,
          work_end_date: Date.current,
          position: 0
        )

        booking.booking_lines.create!(
          description: "Commission #{@job.shop.commission_percent}% — #{@job.shop.name}",
          line_type: :commission,
          booking_type: :project_based,
          rate_ore: @job.commission_amount_ore,
          total_hours: 1,
          work_start_date: Date.current,
          work_end_date: Date.current,
          position: 1
        )

        @job.update!(booking: booking, status: :invoiced)
        booking
      end
    end

    def submit_to_pop(booking)
      pop_client.create_payout(
        worker_id: member_enrollment.pop_worker_id,
        lines: pop_lines,
        invoiced_on: Date.current.iso8601,
        due_on: (Date.current + 14.days).iso8601,
        order_reference: @job.id,
        source_params: { bookify_job_id: @job.id },
        idempotency_key: "bookify-job-#{@job.id}"
      )
    end

    def pop_lines
      [
        {
          description: @job.title,
          line_type: "work",
          rate: @job.work_amount_ore / 100.0,
          quantity: 1,
          work_started_at: Date.current.beginning_of_day.iso8601,
          work_ended_at: Date.current.end_of_day.iso8601,
          group: "job-work"
        },
        {
          description: "Commission #{@job.shop.commission_percent}% — #{@job.shop.name}",
          line_type: "commission",
          rate: @job.commission_amount_ore / 100.0,
          quantity: 1,
          payee_freelance_profile_id: @job.shop.pop_worker_id,
          group: "job-work"
        }
      ]
    end

    def record_payout(booking, data)
      ActiveRecord::Base.transaction do
        booking.create_payout!(
          pop_payout_id: data["id"],
          pop_status: data["status"],
          amount_ore: data["amount"].to_i,
          pop_invoice_number: data["invoice_number"],
          pop_response: data,
          synced_at: Time.current
        )
      end
    end

    def pop_client
      @pop_client ||= PopApiClient.for_user(@job.shop.owner)
    end
  end
end
