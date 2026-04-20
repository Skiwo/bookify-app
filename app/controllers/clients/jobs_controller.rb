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
      @job = current_client.jobs.find(params[:id])

      unless @job.assigned_member.present?
        redirect_to clients_job_path(@job), alert: "Cannot complete: no freelancer has been assigned yet."
        return
      end

      @job.update!(client_completed_at: Time.current)

      if @job.both_completed?
        result = Bookify::InvoicingService.new(@job).call
        if result.success?
          redirect_to clients_job_path(@job), notice: "Both sides confirmed. Invoice issued by Payout Partner AS."
        else
          redirect_to clients_job_path(@job), alert: "Confirmation saved but invoicing failed: #{result.error&.message}"
        end
      else
        redirect_to clients_job_path(@job), notice: "Marked as complete. Waiting for shop confirmation."
      end
    end

    def dispute
      @job = current_client.jobs.where(status: [:in_progress, :accepted]).find(params[:id])
      reason = params.dig(:dispute, :reason).presence || "No reason provided"
      @job.update!(status: :disputed)
      @job.create_dispute!(raised_by: current_user, reason: reason)
      redirect_to clients_job_path(@job), notice: "Dispute raised. We will be in touch shortly."
    end
  end
end
