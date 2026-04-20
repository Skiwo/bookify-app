class JobMessagesController < ApplicationController
  before_action :require_authentication!

  def create
    @job = Job.find(params[:job_id])

    unless authorized_for_job?(@job)
      redirect_to root_path, alert: "Access denied."
      return
    end

    @message = @job.messages.new(body: params[:message][:body], sender: current_user)

    if @message.save
      redirect_to job_show_path(@job), notice: nil
    else
      redirect_back fallback_location: root_path, alert: "Message cannot be blank."
    end
  end

  private

  def authorized_for_job?(job)
    return true if current_user.client? && job.client.user_id == current_user.id
    return true if current_user.shop_owner? && job.shop.owner_id == current_user.id
    return true if current_user.freelancer? && job.assigned_member&.enrollment&.freelancer_id == current_user.id
    false
  end

  def job_show_path(job)
    if current_user.client?
      clients_job_path(job)
    elsif current_user.shop_owner?
      shop_job_path(job)
    else
      root_path
    end
  end
end
