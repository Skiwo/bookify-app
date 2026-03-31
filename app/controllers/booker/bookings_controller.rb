module Booker
  class BookingsController < BaseController
    before_action :require_pop!, only: %i[new create pay]

    def index
      @bookings = Booking.joins(:enrollment)
        .where(enrollments: { booker_id: current_user.id })
        .includes(enrollment: :freelancer)
        .order(created_at: :desc)
        .page(params[:page])
    end

    def new
      @booking = Booking.new
      @enrollments = current_user.enrollments_as_booker.active
      @rate_nok = nil
      load_occupation_codes
    end

    def create
      enrollment = current_user.enrollments_as_booker.active.find(params[:booking][:enrollment_id])
      @booking = enrollment.bookings.build(booking_params)

      rate_nok = params[:rate_nok].to_f
      @booking.rate_ore = (rate_nok * 100).round if rate_nok > 0

      if @booking.save
        redirect_to booker_booking_path(@booking), notice: "Booking created."
      else
        @enrollments = current_user.enrollments_as_booker.active
        @rate_nok = params[:rate_nok]
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
      @rate_nok = @booking.rate_nok
      load_occupation_codes
    end

    def update
      @booking = find_booking
      unless @booking.editable?
        redirect_to(booker_booking_path(@booking), alert: "This booking can no longer be edited.") and return
      end

      rate_nok = params[:rate_nok].to_f
      @booking.rate_ore = (rate_nok * 100).round if rate_nok > 0

      if @booking.update(booking_params)
        redirect_to booker_booking_path(@booking), notice: "Booking updated."
      else
        @rate_nok = params[:rate_nok]
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

      work_started, work_ended = work_timestamps_for(@booking)

      lines = [{
        description: @booking.description,
        rate: @booking.rate_ore / 100.0,
        quantity: @booking.effective_hours,
        occupation_code: @booking.occupation_code,
        work_started_at: work_started&.iso8601,
        work_ended_at: work_ended&.iso8601,
        work_hours: @booking.effective_hours
      }.compact]

      result = pop_client.create_payout(
        worker_id: enrollment.pop_worker_id,
        lines: lines,
        occupation_code: @booking.occupation_code,
        invoiced_on: (@booking.work_date || Date.current).iso8601,
        order_reference: @booking.order_reference,
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
        .find(params[:id])
    end

    def booking_params
      params.require(:booking).permit(:description, :occupation_code, :hours, :work_date, :order_reference,
        :booking_type, :start_time, :end_time, :work_start_date, :work_end_date, :total_hours)
    end

    def load_occupation_codes
      result = pop_client.list_occupation_codes
      all_codes = result.success? ? result.data.fetch("data", []) : []
      @occupation_codes = all_codes.select { |oc| oc["enabled"] != false }
      @occupation_codes_error = result.error unless result.success?
    end

    def work_timestamps_for(booking)
      if booking.time_based?
        date = booking.work_date || Date.current
        started = booking.start_time ? Time.zone.local(date.year, date.month, date.day, booking.start_time.hour, booking.start_time.min) : Time.zone.local(date.year, date.month, date.day, 8, 0)
        ended = booking.end_time ? Time.zone.local(date.year, date.month, date.day, booking.end_time.hour, booking.end_time.min) : started + booking.hours.hours
        [started, ended]
      else
        started = booking.work_start_date&.beginning_of_day
        ended = booking.work_end_date&.end_of_day
        [started, ended]
      end
    end
  end
end
