module ShopAdmin
  class JobsController < BaseController
    include JobReadable
    def index
      @jobs = current_shop.jobs.includes(:client, :assigned_member).order(created_at: :desc)
      @jobs = @jobs.where(status: params[:status]) if params[:status].present?
    end

    def show
      @job = current_shop.jobs.includes(:client, assigned_member: :enrollment).find(params[:id])
      load_messages
      load_read_data
    end

    def issue_quote
      @job = current_shop.jobs.find(params[:id])
      work_ore = (params[:work_amount_nok].to_f * 100).round
      attrs = {
        status: :quoted,
        work_amount_ore: work_ore,
        commission_amount_ore: (@job.shop.commission_percent.to_f / 100 * work_ore).round,
        assigned_member_id: params[:assigned_member_id],
        quote_expires_at: 72.hours.from_now
      }

      if @job.update(attrs)
        redirect_to shop_job_path(@job), notice: "Quote issued."
      else
        redirect_to shop_job_path(@job), alert: "Could not issue quote."
      end
    end

    def sync_payout
      @job = current_shop.jobs.find(params[:id])
      Bookify::PayoutSyncService.new(@job).call
      redirect_to shop_job_path(@job), notice: "Payout status refreshed."
    end

    def mark_complete
      @job = current_shop.jobs.find(params[:id])

      unless @job.assigned_member.present?
        redirect_to shop_job_path(@job), alert: "Cannot complete: no freelancer assigned."
        return
      end

      hours = params[:work_hours].presence&.to_f || 8.0
      @job.update!(
        status: :pending_confirmation,
        completion_marked_at: Time.current,
        confirmation_deadline_at: 48.hours.from_now,
        work_date: params[:work_date].presence&.to_date || Date.current,
        work_hours: hours
      )
      Message.post_system(@job, "#{current_shop.name} marked the job as complete (#{hours}h). Client has 48h to confirm.")
      redirect_to shop_job_path(@job), notice: "Job marked as complete. Client has 48 hours to confirm."
    end

    def respond_dispute
      @job = current_shop.jobs.disputed.find(params[:id])
      response = params.dig(:dispute, :response).presence
      unless response
        redirect_to shop_job_path(@job), alert: "Response cannot be blank."
        return
      end
      @job.dispute.respond!(user: current_user, response: response)
      Message.post_system(@job, "#{current_shop.name} responded to the dispute.")
      redirect_to shop_job_path(@job), notice: "Response sent."
    end

    def resolve_dispute
      @job = current_shop.jobs.disputed.find(params[:id])
      resolution = params.dig(:dispute, :resolution).presence || "Resolved by shop"
      @job.dispute.resolve!(user: current_user, resolution: resolution)
      Message.post_system(@job, "Dispute resolved. Job returned to accepted status.")
      redirect_to shop_job_path(@job), notice: "Dispute resolved. Job is back in progress."
    end
  end
end
