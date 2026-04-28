module Freelancer
  class JobsController < BaseController
    include JobReadable
    def show
      @job = find_job
      load_messages
    end

    def sync_payout
      @job = find_job
      Bookify::PayoutSyncService.new(@job).call
      redirect_to freelancer_job_path(@job), notice: t("flash.payout_refreshed")
    end

    def accept_assignment
      @job = find_job
      @job.update!(member_accepted_at: Time.current)
      name = current_user.name.presence || current_user.email.split("@").first
      Message.post_system(@job, "✓ #{name} accepted the assignment.")
      redirect_to freelancer_job_path(@job), notice: "Assignment accepted."
    end

    def decline_assignment
      @job = find_job
      name = current_user.name.presence || current_user.email.split("@").first
      @job.update!(assigned_member_id: nil, member_accepted_at: nil)
      Message.post_system(@job, "✗ #{name} declined the assignment. Shop can reassign.")
      redirect_to freelancer_dashboard_path, notice: "Assignment declined."
    end

    def mark_complete
      @job = find_job
      unless @job.member_accepted_at.present?
        redirect_to freelancer_job_path(@job), alert: "Accept the assignment first."
        return
      end
      unless @job.in_progress? || @job.accepted?
        redirect_to freelancer_job_path(@job), alert: "Job cannot be marked complete at this stage."
        return
      end
      hours = (params[:work_hours].presence&.to_f || 8.0).clamp(0.5, 24.0)
      @job.update!(
        status: :pending_confirmation,
        completion_marked_at: Time.current,
        confirmation_deadline_at: 48.hours.from_now,
        work_date: params[:work_date].presence&.to_date || Date.current,
        work_hours: hours
      )
      name = current_user.name.presence || current_user.email.split("@").first
      Message.post_system(@job, "#{name} marked the job as complete (#{hours}h). Client has 48h to confirm.")
      redirect_to freelancer_job_path(@job), notice: t("flash.job_complete")
    end

    private

    def find_job
      assigned = Job.joins(assigned_member: :enrollment)
                    .where(enrollments: { freelancer_id: current_user.id })
      solo_owned = Job.joins(:shop).where(shops: { owner_id: current_user.id, solo: true })
      Job.where(id: assigned.select(:id)).or(Job.where(id: solo_owned.select(:id)))
         .includes(:shop, :client, assigned_member: :enrollment)
         .find(params[:id])
    end
  end
end
