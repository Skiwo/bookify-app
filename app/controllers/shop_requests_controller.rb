class ShopRequestsController < ApplicationController
  def create
    @shop = Shop.active.find_by!(slug: params[:slug])
    @job = @shop.jobs.new(job_params.merge(status: :draft))

    if @job.save
      redirect_to shop_path(@shop.slug), notice: "Your request has been sent to the shop."
    else
      @members = @shop.active_members.includes(:enrollment)
      render "shops/show", status: :unprocessable_entity
    end
  end

  private

  def job_params
    params.require(:job).permit(:title, :description, :client_id)
  end
end
