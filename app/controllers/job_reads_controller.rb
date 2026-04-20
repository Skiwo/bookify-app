class JobReadsController < ApplicationController
  before_action :require_authentication!

  def create
    job = Job.find(params[:job_id])
    unless authorized_for_job?(job)
      head :forbidden
      return
    end

    JobRead.upsert(
      { job_id: job.id, user_id: current_user.id, last_read_at: Time.current,
        created_at: Time.current, updated_at: Time.current },
      unique_by: [:job_id, :user_id]
    )

    head :ok
  end

  private

  def authorized_for_job?(job)
    return true if current_user.client? && job.client.user_id == current_user.id
    return true if current_user.shop_owner? && job.shop.owner_id == current_user.id
    return true if current_user.freelancer? && job.assigned_member&.enrollment&.freelancer_id == current_user.id
    false
  end
end
