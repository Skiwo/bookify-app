module Clients
  class JobsController < BaseController
    include JobReadable

    def index
      @jobs = current_client.jobs.includes(:shop).order(created_at: :desc)
      @jobs = @jobs.where(status: params[:status]) if params[:status].present?
    end

    def show
      @job = current_client.jobs.includes(:shop, assigned_member: :enrollment).find(params[:id])
      @messages = @job.messages.includes(:sender).order(:created_at)
      load_read_data
    end

    def mark_complete
      @job = current_client.jobs.pending_confirmation.find(params[:id])
      actual_hours   = params[:work_hours].presence&.to_f || @job.work_hours || 8.0
      work_ore       = @job.rate_per_hour_ore.present? ? (@job.rate_per_hour_ore * actual_hours).round : @job.work_amount_ore
      commission_ore = (@job.shop.commission_percent.to_f / 100 * work_ore).round

      @job.update!(
        work_date:            params[:work_date].presence&.to_date || @job.work_date || Date.current,
        work_hours:           actual_hours,
        work_amount_ore:      work_ore,
        commission_amount_ore: commission_ore
      )
      result = Bookify::InvoicingService.new(@job).call

      if result.success?
        Message.post_system(@job, "✓ #{current_client.org_name} confirmed completion (#{@job.work_hours}h on #{@job.work_date&.strftime("%d %b")}). Invoice issued by Payout Partner AS.")
        redirect_to clients_job_path(@job), notice: "Job confirmed. Invoice will be issued by Payout Partner AS within 24 hours."
      else
        redirect_to clients_job_path(@job), alert: "Could not issue invoice: #{result.error&.message}. Please contact support."
      end
    end

    def cancel
      @job = current_client.jobs.where(status: [:draft, :quoted]).find(params[:id])
      @job.update!(status: :cancelled)
      Message.post_system(@job, "✗ Request cancelled by #{current_client.org_name}.")
      redirect_to clients_jobs_path, notice: "Request cancelled."
    end

    def dispute
      @job = current_client.jobs.pending_confirmation.find(params[:id])
      reason = params.dig(:dispute, :reason).presence || "No reason provided"
      @job.update!(status: :disputed)
      @job.create_dispute!(raised_by: current_user, reason: reason)
      redirect_to clients_job_path(@job), notice: "Dispute raised. We will be in touch shortly."
    end
  end
end
