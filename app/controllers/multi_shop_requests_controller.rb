class MultiShopRequestsController < ApplicationController
  before_action :require_authentication!
  before_action :require_client!

  def create
    slugs  = Array(params[:shop_slugs]).map(&:strip).reject(&:blank?).first(5).uniq
    shops  = Shop.active.public_shop.where(slug: slugs)
    title  = params.dig(:job, :title).presence

    if shops.empty?
      redirect_back fallback_location: shops_path, alert: "Select at least one shop."
      return
    end

    unless title
      redirect_back fallback_location: shops_path, alert: "Please provide a title for your request."
      return
    end

    jobs = shops.map do |shop|
      job = shop.jobs.create!(
        title: title,
        description: params.dig(:job, :description).presence,
        desired_date:  params.dig(:job, :desired_date).presence&.to_date,
        desired_hours: params.dig(:job, :desired_hours).presence&.to_f,
        client: current_client,
        status: :draft
      )
      Message.post_system(job, "Request submitted by #{current_client.org_name}.")
      JobMailer.new_request(job).deliver_later
      job
    end

    if jobs.one?
      redirect_to clients_job_path(jobs.first), notice: "Request sent to #{shops.first.name}."
    else
      redirect_to clients_jobs_path, notice: "Request sent to #{jobs.size} shops."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: shops_path, alert: e.message
  end

  private

  def require_client!
    return if current_user&.client?
    redirect_to new_clients_registration_path,
      alert: "Please register your organisation before sending requests."
  end

  def current_client
    @current_client ||= Client.find_by!(user: current_user)
  end
end
