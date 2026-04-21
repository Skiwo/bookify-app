module ShopAdmin
  class QuotesController < BaseController
    def new
      @job = current_shop.jobs.find(params[:job_id])
      @members = current_shop.shop_members.active.includes(:enrollment)
    end

    def create
      @job = current_shop.jobs.find(params[:job_id])
      rate_ore       = (params[:rate_per_hour_nok].to_f * 100).round
      est_hours      = params[:estimated_hours].to_f
      work_ore       = (rate_ore * est_hours).round
      commission_ore = (@job.shop.commission_percent.to_f / 100 * work_ore).round

      if @job.update(
        status: :quoted,
        rate_per_hour_ore: rate_ore,
        estimated_hours: est_hours,
        work_amount_ore: work_ore,
        commission_amount_ore: commission_ore,
        assigned_member_id: params[:assigned_member_id],
        quote_expires_at: 72.hours.from_now
      )
        total_nok = work_ore / 100.0
        Message.post_system(@job, "Quote sent by #{current_shop.name}: kr #{total_nok.to_i} (#{params[:rate_per_hour_nok]} kr/h × #{est_hours}h). Valid 72 hours.")
        redirect_to shop_job_path(@job), notice: "Quote sent to client."
      else
        @members = current_shop.shop_members.active.includes(:enrollment)
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @job = current_shop.jobs.find(params[:id])
    end
  end
end
