module Clients
  class QuotesController < BaseController
    def index
      @jobs = current_client.jobs.quoted.order(created_at: :desc)
    end

    def show
      @job = current_client.jobs.find(params[:id])
    end

    def accept
      @job = current_client.jobs.quoted.find(params[:id])

      if @job.quote_expired?
        redirect_to clients_quote_path(@job), alert: "This quote has expired."
        return
      end

      @job.update!(status: :accepted)
      redirect_to clients_job_path(@job), notice: "Quote accepted! Chat is now open."
    end

    def decline
      @job = current_client.jobs.quoted.find(params[:id])
      @job.update!(status: :draft)
      redirect_to clients_quotes_path, notice: "Quote declined."
    end
  end
end
