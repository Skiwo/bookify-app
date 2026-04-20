module Clients
  class RequestsController < BaseController
    def index
      @jobs = current_client.jobs.draft.order(created_at: :desc)
    end

    def show
      @job = current_client.jobs.find(params[:id])
    end
  end
end
