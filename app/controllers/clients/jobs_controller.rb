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

    def confirm
      @job = current_client.jobs.pending_confirmation.find(params[:id])
      result = Bookify::InvoicingService.new(@job).call

      if result.success?
        redirect_to clients_job_path(@job), notice: "Job confirmed. Invoice will be issued by Payout Partner AS within 24 hours."
      else
        redirect_to clients_job_path(@job), alert: "Could not issue invoice: #{result.error&.message}. Please contact support."
      end
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
