class ShopRequestsController < ApplicationController
  before_action :require_authentication!
  before_action :require_client!

  def create
    @shop = Shop.active.find_by!(slug: params[:slug])
    @job = @shop.jobs.new(
      title: params.dig(:job, :title),
      description: params.dig(:job, :description),
      desired_date: params.dig(:job, :desired_date).presence,
      desired_hours: params.dig(:job, :desired_hours).presence&.to_f,
      client: current_client,
      status: :draft
    )

    if @job.save
      Message.post_system(@job, "Request submitted by #{current_client.org_name}.")
      redirect_to clients_job_path(@job), notice: "Request sent to #{@shop.name}. Chat is open — feel free to discuss details."
    else
      @members = @shop.active_members.includes(:enrollment)
      render "shops/show", status: :unprocessable_entity
    end
  end

  private

  def require_client!
    return if current_user&.client?
    redirect_to new_clients_registration_path,
      alert: "Please register your organisation before submitting a request."
  end

  def current_client
    @current_client ||= Client.find_by!(user: current_user)
  end
end
