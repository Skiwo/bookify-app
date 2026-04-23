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
        @job.update!(booking: booking, status: :invoiced)
        record_payout(booking, result.data)
        Result.new(success: true)
      else
        booking.destroy
        Result.new(success: false, error: result.error)
      end
    end

    private

    def validate!
      raise ArgumentError, "No assigned member" unless @job.assigned_member
      raise ArgumentError, "No work amount" unless @job.work_amount_ore.to_i > 0
      raise ArgumentError, "Shop owner not enrolled in POP" unless @job.shop.pop_worker_id.present?
      raise ArgumentError, "Member not enrolled in POP" unless member_pop_worker_id.present?
      # Requires credentials.yml.enc: bookify: { pop_profile_id: "<FreelanceProfile UUID>" }
      if @job.bookify_fee? && Rails.application.credentials.dig(:bookify, :pop_profile_id).blank?
        raise ArgumentError, "Bookify POP profile not configured"
      end
    end

    def member_pop_worker_id
      @job.assigned_member.bookify_pop_worker_id
    end

    def build_booking_in_db
      ActiveRecord::Base.transaction do
        booking = Booking.new(
          enrollment: @job.assigned_member.enrollment,
          description: @job.title,
          invoiced_on: Date.current,
          due_on: Date.current + 14.days,
          status: :completed
        )

        build_work_lines(booking)

        booking.booking_lines.build(
          description: "Commission #{@job.shop.commission_percent}% — #{@job.shop.name}",
          line_type: :commission,
          booking_type: :project_based,
          rate_ore: @job.commission_amount_ore,
          total_hours: 1,
          work_start_date: Date.current,
          work_end_date: Date.current,
          position: @job.quote_lines.size + 1
        )

        if @job.bookify_fee?
          booking.booking_lines.build(
            description: "Bookify platform fee",
            line_type: :commission,
            booking_type: :project_based,
            rate_ore: Job::BOOKIFY_FEE_ORE,
            total_hours: 1,
            work_start_date: Date.current,
            work_end_date: Date.current,
            position: @job.quote_lines.size + 2
          )
        end

        booking.save!
        booking
      end
    end

    def build_work_lines(booking)
      if @job.quote_lines.any?
        @job.quote_lines.order(:position).each_with_index do |ql, i|
          booking.booking_lines.build(
            description: ql.description,
            line_type: :work,
            booking_type: :project_based,
            rate_ore: ql.amount_ore,
            total_hours: ql.hours,
            work_start_date: @job.work_date || Date.current,
            work_end_date: @job.work_date || Date.current,
            position: i
          )
        end
      else
        booking.booking_lines.build(
          description: @job.title,
          line_type: :work,
          booking_type: :project_based,
          rate_ore: @job.work_amount_ore,
          total_hours: 1,
          work_start_date: @job.work_date || Date.current,
          work_end_date: @job.work_date || Date.current,
          position: 0
        )
      end
    end

    def submit_to_pop(booking)
      pop_client.create_payout(
        worker_id: member_pop_worker_id,
        lines: pop_lines,
        invoiced_on: Date.current.iso8601,
        due_on: (Date.current + 14.days).iso8601,
        order_reference: "bookify-job-#{@job.id}",
        buyer_reference: @job.client.org_number,
        external_note: @job.client.org_name,
        source_params: { bookify_job_id: @job.id, shop_id: @job.shop_id },
        idempotency_key: "bookify-job-#{@job.id}"
      )
    end

    def pop_lines
      work = if @job.quote_lines.any?
        @job.quote_lines.order(:position).map do |ql|
          {
            description: ql.description,
            line_type: "work",
            rate: ql.amount_ore / 100.0,
            quantity: 1,
            work_started_at: work_started_at.iso8601,
            work_ended_at: work_ended_at.iso8601,
            work_hours: ql.hours,
            group: "job-work"
          }
        end
      else
        [{
          description: @job.title,
          line_type: "work",
          rate: @job.work_amount_ore / 100.0,
          quantity: 1,
          work_started_at: work_started_at.iso8601,
          work_ended_at: work_ended_at.iso8601,
          work_hours: @job.work_hours,
          group: "job-work"
        }]
      end

      commission = [{
        description: "Commission #{@job.shop.commission_percent}% — #{@job.shop.name}",
        line_type: "commission",
        rate: @job.commission_amount_ore / 100.0,
        quantity: 1,
        payee_freelance_profile_id: @job.shop.pop_worker_id,
        group: "job-work"
      }]

      if @job.bookify_fee?
        commission << {
          description: "Bookify platform fee",
          line_type: "commission",
          rate: Job::BOOKIFY_FEE_ORE / 100.0,
          quantity: 1,
          payee_freelance_profile_id: Rails.application.credentials.dig(:bookify, :pop_profile_id),
          group: "job-work"
        }
      end

      work + commission
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

    def work_started_at
      date = @job.work_date || Date.current
      Time.zone.local(date.year, date.month, date.day, 9, 0)
    end

    def work_ended_at
      work_started_at + (@job.work_hours || 8.0).hours
    end

    def pop_client
      @pop_client ||= PopApiClient.for_bookify
    end
  end
end
