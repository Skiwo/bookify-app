module Clients
  class QuotesController < BaseController
    def index
      @jobs = current_client.jobs.quoted.order(created_at: :desc)
    end

    def show
      @job = current_client.jobs.find(params[:id])
    end

    def accept
      @job = current_client.jobs.quoted.lock.find(params[:id])

      if @job.quote_expired?
        redirect_to clients_quote_path(@job), alert: t("flash.quote_expired_alert")
        return
      end

      @job.update!(status: :in_progress)
      Message.post_system(@job, "✓ Quote accepted by #{current_client.org_name}. Work is in progress.")
      JobMailer.quote_accepted(@job).deliver_later
      JobMailer.member_assigned(@job).deliver_later if @job.assigned_member
      redirect_to clients_job_path(@job), notice: t("flash.quote_accepted")
    end

    def decline
      @job = current_client.jobs.quoted.find(params[:id])
      @job.update!(status: :draft)
      Message.post_system(@job, "✗ Quote declined by #{current_client.org_name}.")
      JobMailer.quote_declined(@job).deliver_later
      redirect_to clients_quotes_path, notice: t("flash.quote_declined")
    end
  end
end
