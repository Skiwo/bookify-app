module ShopAdmin
  class QuotesController < BaseController
    def new
      @job = current_shop.jobs.find(params[:job_id])
      @members = current_shop.shop_members.active.includes(:enrollment)
    end

    def create
      @job = current_shop.jobs.find(params[:job_id])
      work_ore = (params[:work_amount_nok].to_f * 100).round
      commission_ore = (@job.shop.commission_percent.to_f / 100 * work_ore).round

      if @job.update(
        status: :quoted,
        work_amount_ore: work_ore,
        commission_amount_ore: commission_ore,
        assigned_member_id: params[:assigned_member_id],
        quote_expires_at: 72.hours.from_now
      )
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
