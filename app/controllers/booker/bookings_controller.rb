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

      ordered = @booking.booking_lines.order(:position)
      # API v2: each work line is a work_line (unit_price in øre, a duration);
      # all dependent lines (expense/benefit/diet) nest as sub_lines under the
      # first work line. amount = unit_price × quantity.
      sub_lines = ordered.reject(&:work?).map { |line| build_sub_line(line) }

      work_lines = ordered.select(&:work?).each_with_index.map do |line, idx|
        wl = {
          description: line.description,
          occupation_code: line.occupation_code.presence,
          unit_price: line.rate_ore,
          quantity: line.effective_hours,
          duration: duration_for(line)
        }.compact
        wl[:sub_lines] = sub_lines if idx.zero? && sub_lines.any?
        wl
      end

      # Sub-lines (expense/diet/benefit) attach to a work line; a booking with no
      # work line would send empty work_lines and POP would 422. Catch it here
      # with a message the booker can act on, and don't silently drop the subs.
      if work_lines.empty?
        redirect_to(booker_booking_path(@booking),
          alert: "Add at least one work line before paying — expenses and per-diems attach to a work line.") and return
      end

      result = pop_client.create_payout(
        worker_id: enrollment.pop_worker_id,
        idempotency_key: "booking-#{@booking.id}",
        work_lines: work_lines,
        invoiced_on: @booking.invoiced_on&.iso8601, # else POP derives from the last work end date
        due_on: @booking.due_on&.iso8601,
        buyer_reference: @booking.buyer_reference.presence,
        order_reference: @booking.order_reference.presence,
        external_note: @booking.external_note.presence
      )

      if result.success?
        begin
          ActiveRecord::Base.transaction do
            @booking.create_payout!(
              pop_payout_id: result.data["id"],
              pop_status: result.data["status"],
              amount_ore: result.data["amount"].to_i,
              pop_invoice_number: result.data["invoice_number"],
              pop_response: result.data,
              synced_at: Time.current
            )
            @booking.update!(status: :paid)
          end
          redirect_to booker_payout_path(@booking.payout), notice: "Payout created successfully."
        rescue ActiveRecord::RecordInvalid => e
          redirect_to booker_booking_path(@booking), alert: "Payout failed: #{e.record.errors.full_messages.to_sentence}"
        end
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
          :total_hours, :work_start_date, :work_end_date, :line_external_id,
          :receipt_url, :trip_type, :position
        ]
      )
    end

    def load_occupation_codes
      result = pop_client.list_occupation_codes
      all_codes = result.success? ? result.data.fetch("data", []) : []
      @occupation_codes = all_codes.select { |oc| oc["enabled"] != false }
      @occupation_codes_error = result.error unless result.success?
    end

    # Earning date + worked hours for a work line. Hours present → POP files it
    # as timeloenn (hourly); date only would be honorar (commission).
    def duration_for(line)
      if line.time_based?
        date = line.work_date&.iso8601
        { start_date: date, end_date: date, duration_hours: line.hours }.compact
      else
        {
          start_date: line.work_start_date&.iso8601,
          end_date: line.work_end_date&.iso8601,
          duration_hours: line.total_hours
        }.compact
      end
    end

    # A dependent (non-work) booking line → a v2 sub_line. unit_price in øre
    # (the per-unit amount); quantity defaults to 1 for flat items. expense lines
    # carry a receipt_url (POP fetches it server-side, so it must be a public
    # URL); diet lines carry a trip_type + a per-day unit_price × quantity (days)
    # — POP splits each day tax-free up to the satser for the band. The model
    # validations guarantee both fields are present here.
    def build_sub_line(line)
      sub = {
        line_type: line.line_type,
        unit_price: line.rate_ore,
        quantity: line.effective_hours.positive? ? line.effective_hours : 1
      }
      sub[:receipt_url] = line.receipt_url if line.expense?
      sub[:trip_type] = line.trip_type if line.diet?
      sub
    end
  end
end
