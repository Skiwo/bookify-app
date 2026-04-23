module ShopAdmin
  class QuotesController < BaseController
    def new
      @job = current_shop.jobs.find(params[:job_id])
      @members = current_shop.shop_members.active.includes(:enrollment)
    end

    def create
      @job = current_shop.jobs.find(params[:job_id])
      lines_params = Array(params[:quote_lines])

      if lines_params.empty?
        redirect_to new_shop_quote_path(job_id: @job.id), alert: "Add at least one activity."
        return
      end

      work_ore = 0
      quote_lines = lines_params.map.with_index do |lp, i|
        rate_ore = (lp[:rate_nok].to_f * 100).round
        hours = lp[:hours].to_f
        amount_ore = (rate_ore * hours).round
        work_ore += amount_ore
        { description: lp[:description], rate_ore: rate_ore, hours: hours, amount_ore: amount_ore, position: i }
      end

      commission_ore = (current_shop.commission_percent.to_f / 100 * work_ore).round

      ActiveRecord::Base.transaction do
        @job.quote_lines.destroy_all
        quote_lines.each { |ql| @job.quote_lines.create!(ql) }
        @job.update!(
          status: :quoted,
          work_amount_ore: work_ore,
          commission_amount_ore: commission_ore,
          assigned_member_id: params[:assigned_member_id],
          quote_expires_at: 72.hours.from_now
        )
      end

      summary = quote_lines.map { |ql| "#{ql[:description]} (kr #{ql[:amount_ore] / 100})" }.join(", ")
      Message.post_system(@job, "Quote sent by #{current_shop.name}: #{summary}. Total: kr #{work_ore / 100}. Valid 72 hours.")
      JobMailer.quote_sent(@job).deliver_later
      redirect_to shop_job_path(@job), notice: "Quote sent to client."
    rescue ActiveRecord::RecordInvalid => e
      @members = current_shop.shop_members.active.includes(:enrollment)
      redirect_to new_shop_quote_path(job_id: @job.id), alert: e.message
    end

    def show
      @job = current_shop.jobs.find(params[:id])
    end
  end
end
