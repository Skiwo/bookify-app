class JobReadsController < ApplicationController
  before_action :require_authentication!

  def create
    job = Job.find(params[:job_id])
    unless authorized_for_job?(job)
      head :forbidden
      return
    end

    now = Time.current
    JobRead.upsert(
      { job_id: job.id, user_id: current_user.id, last_read_at: now,
        created_at: now, updated_at: now },
      unique_by: [:job_id, :user_id]
    )

    ActionCable.server.broadcast("job_#{job.id}", {
      type: "read",
      user_id: current_user.id,
      read_at: now.iso8601
    })

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
