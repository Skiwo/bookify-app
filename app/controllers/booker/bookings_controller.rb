module Booker
  class BookingsController < BaseController
    before_action :require_pop!, only: %i[new create pay]

    def index
      @bookings = Booking.joins(:enrollment)
        .where(enrollments: { booker_id: current_user.id })
        .includes(:booking_lines, enrollment: :freelancer)
        .order(created_at: :desc)
        .page(params[:page])
    end

    def new
      @booking = Booking.new
      @booking.booking_lines.build
      @enrollments = current_user.enrollments_as_booker.active
      load_occupation_codes
    end

    def create
      enrollment = current_user.enrollments_as_booker.active.find(params[:booking][:enrollment_id])
      @booking = enrollment.bookings.build(booking_params)

      if @booking.save
        redirect_to booker_booking_path(@booking), notice: "Booking created."
      else
        @enrollments = current_user.enrollments_as_booker.active
        @booking.booking_lines.build if @booking.booking_lines.empty?
        load_occupation_codes
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @booking = find_booking
    end

    def edit
      @booking = find_booking
      unless @booking.editable?
        redirect_to(booker_booking_path(@booking), alert: "This booking can no longer be edited.") and return
      end
      load_occupation_codes
    end

    def update
      @booking = find_booking
      unless @booking.editable?
        redirect_to(booker_booking_path(@booking), alert: "This booking can no longer be edited.") and return
      end

      if @booking.update(booking_params)
        redirect_to booker_booking_path(@booking), notice: "Booking updated."
      else
        @booking.booking_lines.build if @booking.booking_lines.reject(&:marked_for_destruction?).empty?
        load_occupation_codes
        render :edit, status: :unprocessable_entity
      end
    end

    def complete
      @booking = find_booking

      unless @booking.draft?
        redirect_to(booker_booking_path(@booking), alert: "Only draft bookings can be marked as completed.") and return
      end

      @booking.update!(status: :completed)
      redirect_to booker_booking_path(@booking), notice: "Booking marked as completed."
    end

    def uncomplete
      @booking = find_booking

      unless @booking.can_uncomplete?
        redirect_to(booker_booking_path(@booking), alert: "This booking cannot be reverted.") and return
      end

      @booking.update!(status: :draft)
      redirect_to booker_booking_path(@booking), notice: "Booking reverted to draft."
    end

    def pay
      @booking = find_booking

      if @booking.payout.present?
        redirect_to(booker_booking_path(@booking), alert: "This booking has already been paid.") and return
      end

      unless @booking.completed?
        redirect_to(booker_booking_path(@booking), alert: "Booking must be completed before payment.") and return
      end

      enrollment = @booking.enrollment

      lines = @booking.booking_lines.order(:position).map do |line|
        payout_line = {
          description: line.description,
          line_type: line.line_type,
          rate: line.rate_ore / 100.0,
          quantity: line.effective_hours,
          occupation_code: line.occupation_code.presence,
          external_id: line.line_external_id.presence,
          receipt_url: line.receipt_url.presence
        }

        if line.work?
          work_started, work_ended = work_timestamps_for_line(line)
          payout_line[:work_started_at] = work_started&.iso8601
          payout_line[:work_ended_at] = work_ended&.iso8601
          payout_line[:work_hours] = line.effective_hours
          payout_line[:group] = "line-#{line.position}"
        else
          # Dependent lines reference the first work line's group
          first_work = @booking.booking_lines.order(:position).find(&:work?)
          payout_line[:group] = "line-#{first_work.position}" if first_work
        end

        payout_line.compact
      end

      invoiced_on_date = @booking.invoiced_on.presence ||
        @booking.booking_lines.first&.work_date.presence ||
        @booking.booking_lines.first&.work_start_date.presence ||
        Date.current

      result = pop_client.create_payout(
        worker_id: enrollment.pop_worker_id,
        lines: lines,
        invoiced_on: invoiced_on_date.iso8601,
        due_on: @booking.due_on&.iso8601,
        buyer_reference: @booking.buyer_reference.presence,
        order_reference: @booking.order_reference.presence,
        external_note: @booking.external_note.presence,
        idempotency_key: "booking-#{@booking.id}"
      )

      if result.success?
        ActiveRecord::Base.transaction do
          @booking.create_payout!(
            pop_payout_id: result.data["id"],
            pop_status: result.data["status"],
            amount_ore: result.data["amount"] || @booking.total_ore,
            pop_invoice_number: result.data["invoice_number"],
            pop_response: result.data,
            synced_at: Time.current
          )
          @booking.update!(status: :paid)
        end
        redirect_to booker_payout_path(@booking.payout), notice: "Payout created successfully."
      else
        redirect_to booker_booking_path(@booking), alert: "Payout failed: #{helpers.format_pop_error(result.error)}"
      end
    end

    private

    def find_booking
      Booking.joins(:enrollment)
        .where(enrollments: { booker_id: current_user.id })
        .includes(:booking_lines)
        .find(params[:id])
    end

    def booking_params
      params.require(:booking).permit(
        :description, :order_reference, :invoiced_on, :due_on,
        :buyer_reference, :external_note,
        booking_lines_attributes: [
          :id, :_destroy, :description, :occupation_code, :booking_type, :line_type,
          :rate_nok, :hours, :work_date, :start_time, :end_time,
          :total_hours, :work_start_date, :work_end_date, :line_external_id, :receipt_url, :position
        ]
      )
    end

    def load_occupation_codes
      result = pop_client.list_occupation_codes
      all_codes = result.success? ? result.data.fetch("data", []) : []
      @occupation_codes = all_codes.select { |oc| oc["enabled"] != false }
      @occupation_codes_error = result.error unless result.success?
    end

    def work_timestamps_for_line(line)
      if line.time_based?
        date = line.work_date || Date.current
        started = line.start_time ? Time.zone.local(date.year, date.month, date.day, line.start_time.hour, line.start_time.min) : Time.zone.local(date.year, date.month, date.day, 8, 0)
        ended = line.end_time ? Time.zone.local(date.year, date.month, date.day, line.end_time.hour, line.end_time.min) : started + line.hours.hours
        [started, ended]
      else
        started = line.work_start_date&.beginning_of_day
        ended = line.work_end_date&.end_of_day
        [started, ended]
      end
    end
  end
end
