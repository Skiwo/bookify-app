class JobChannel < ApplicationCable::Channel
  def subscribed
    job = Job.find_by(id: params[:job_id])
    reject unless job && authorized?(job)
    stream_from "job_#{params[:job_id]}"
  end

  private

  def authorized?(job)
    return true if current_user.client? && job.client.user_id == current_user.id
    return true if current_user.shop_owner? && job.shop.owner_id == current_user.id
    return true if current_user.freelancer? && job.assigned_member&.enrollment&.freelancer_id == current_user.id
    false
  end
end
