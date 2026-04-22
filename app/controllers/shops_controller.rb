class ShopsController < ApplicationController
  def index
    @shops = Shop.active.order(:name)
    @shops = @shops.where("city ILIKE ?", "%#{params[:city]}%") if params[:city].present?
    @shops = @shops.where("EXISTS (SELECT 1 FROM unnest(skill_tags) AS tag WHERE tag ILIKE ?)", "%#{params[:skill]}%") if params[:skill].present?
  end

  def show
    @shop = Shop.find_by!(slug: params[:slug])

    if @shop.closed?
      redirect_to shops_path, alert: "This shop is no longer available."
      return
    end

    if @shop.paused? && !existing_client_of_shop?(@shop)
      redirect_to shops_path, alert: "This shop is temporarily paused and not accepting new requests."
      return
    end

    @members = @shop.active_members.includes(:enrollment)
  end

  private

  def existing_client_of_shop?(shop)
    return false unless current_user&.client?
    client = Client.find_by(user: current_user)
    return false unless client
    shop.jobs.exists?(client: client)
  end
end
