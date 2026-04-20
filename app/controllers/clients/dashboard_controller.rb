module Clients
  class DashboardController < BaseController
    def show
      @client = current_client
      @open_jobs = @client.jobs.where(status: [:quoted, :accepted, :in_progress, :pending_confirmation]).order(created_at: :desc)
      @recent_jobs = @client.jobs.order(created_at: :desc).limit(5)
    end
  end
end
